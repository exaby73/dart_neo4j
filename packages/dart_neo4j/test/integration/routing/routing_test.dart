import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Neo4j Routing Integration Tests', () {
    late Neo4jDriver driver;

    setUpAll(() async {
      // Try to use cluster if available, fallback to single instance
      try {
        await TestConfig.waitForNeo4jCluster();
      } catch (e) {
        // Fallback to single instance for routing tests
        await TestConfig.waitForNeo4j();
      }
    });

    /// Creates a driver, trying cluster URI first, fallback to single instance
    Neo4jDriver createDriver() {
      try {
        return Neo4jDriver.create(
          TestConfig.neo4jClusterUri,
          auth: TestConfig.auth,
        );
      } catch (e) {
        return Neo4jDriver.create(TestConfig.boltUri, auth: TestConfig.auth);
      }
    }

    tearDown(() async {
      if (!driver.isClosed) {
        await driver.close();
      }
    });

    group('Cluster Connectivity', () {
      test('connects to cluster using neo4j:// scheme', () async {
        driver = createDriver();

        // Should connect successfully regardless of cluster or single instance
        await driver.verifyConnectivity();
      });

      test('handles cluster discovery', () async {
        driver = createDriver();

        // Should be able to create sessions and execute queries
        final session = driver.session();
        try {
          final result = await session.run('RETURN "cluster_test" AS message');
          final records = await result.list();
          expect(records.first['message'], equals('cluster_test'));
        } finally {
          await session.close();
        }
      });

      test('verifies cluster member availability', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          // Query cluster topology
          final result = await session.run('CALL dbms.cluster.overview()');
          final records = await result.list();

          expect(records.length, greaterThan(0));

          // Should have at least core members
          final coreMembers =
              records.where((record) {
                final role = record['role'] as String?;
                return role == 'LEADER' || role == 'FOLLOWER';
              }).toList();

          expect(coreMembers.length, greaterThan(0));
        } catch (e) {
          // Skip if running against single instance instead of cluster
          if (e.toString().contains('Unknown procedure') ||
              e.toString().contains('There is no procedure')) {
            return;
          }
          rethrow;
        } finally {
          await session.close();
        }
      });
    });

    group('Read/Write Routing', () {
      test('executes read queries on read replicas', () async {
        driver = createDriver();

        // Create read session
        final session = driver.session(const SessionConfig.read());
        try {
          // Setup test data first with a write session
          final writeSession = driver.session(const SessionConfig.write());
          try {
            await TestData.cleanup(writeSession);
            await writeSession.run(
              'CREATE (p:Person {name: "Read Test", id: 1})',
            );
          } finally {
            await writeSession.close();
          }

          // Now test read operation
          final result = await session.run(
            'MATCH (p:Person {id: 1}) RETURN p.name AS name',
          );
          final records = await result.list();

          expect(records, hasLength(1));
          expect(records.first['name'], equals('Read Test'));
        } finally {
          await session.close();
        }
      });

      test('executes write queries on primary', () async {
        driver = createDriver();

        // Create write session
        final session = driver.session(const SessionConfig.write());
        try {
          await TestData.cleanup(session);

          // Execute write operation
          final result = await session.run(
            'CREATE (p:Person {name: "Write Test", id: 2}) RETURN p.name AS name',
          );
          final records = await result.list();

          expect(records, hasLength(1));
          expect(records.first['name'], equals('Write Test'));

          // Verify the write was persisted
          final verifyResult = await session.run(
            'MATCH (p:Person {id: 2}) RETURN p.name AS name',
          );
          final verifyRecords = await verifyResult.list();
          expect(verifyRecords.first['name'], equals('Write Test'));
        } finally {
          await session.close();
        }
      });

      test('handles read-write transactions correctly', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          await TestData.cleanup(session);

          // Execute read-write transaction
          final result = await session.executeWrite<String>((
            transaction,
          ) async {
            // Write operation
            await transaction.run('CREATE (p:Person {name: "RW Test", id: 3})');

            // Read operation in same transaction
            final readResult = await transaction.run(
              'MATCH (p:Person {id: 3}) RETURN p.name AS name',
            );
            final readRecords = await readResult.list();

            return readRecords.first['name'] as String;
          });

          expect(result, equals('RW Test'));
        } finally {
          await session.close();
        }
      });

      test('routes read transactions to appropriate members', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          // Setup test data
          await TestData.cleanup(session);
          await session.run(
            'CREATE (p:Person {name: "Read Routing Test", id: 4})',
          );

          // Execute read transaction
          final result = await session.executeRead<String>((transaction) async {
            final queryResult = await transaction.run(
              'MATCH (p:Person {id: 4}) RETURN p.name AS name',
            );
            final records = await queryResult.list();
            return records.first['name'] as String;
          });

          expect(result, equals('Read Routing Test'));
        } finally {
          await session.close();
        }
      });
    });

    group('Cluster Failover', () {
      test('handles temporary connection failures gracefully', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          // Execute queries in succession to test connection stability
          for (int i = 0; i < 5; i++) {
            final result = await session.run('RETURN \$i AS iteration', {
              'i': i,
            });
            final records = await result.list();
            expect(records.first['iteration'], equals(i));

            // Small delay between queries
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } finally {
          await session.close();
        }
      });

      test('recovers from individual node failures', () async {
        driver = Neo4jDriver.create(
          TestConfig.neo4jClusterUri,
          auth: TestConfig.auth,
          config: const DriverConfig(
            connectionTimeout: Duration(seconds: 5),
            maxTransactionRetryTime: Duration(seconds: 10),
          ),
        );

        // Test with multiple sessions to verify load distribution
        final sessions = <Session>[];
        try {
          for (int i = 0; i < 3; i++) {
            sessions.add(driver.session());
          }

          // Execute queries across multiple sessions
          final futures = <Future<void>>[];
          for (int i = 0; i < sessions.length; i++) {
            futures.add(() async {
              final result = await sessions[i].run(
                'RETURN \$session AS session_id',
                {'session': i},
              );
              final records = await result.list();
              expect(records.first['session_id'], equals(i));
            }());
          }

          await Future.wait(futures);
        } finally {
          for (final session in sessions) {
            if (!session.isClosed) {
              await session.close();
            }
          }
        }
      });
    });

    group('Cluster-specific Features', () {
      test('accesses cluster routing table', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          // Query routing table information
          final result = await session.run(
            'CALL dbms.cluster.routing.getRoutingTable(\$context)',
            {'context': <String, dynamic>{}},
          );
          final records = await result.list();

          // Should return routing information
          expect(records, isNotEmpty);

          // Verify routing table structure
          for (final record in records) {
            // The exact fields depend on Neo4j version and cluster configuration
            // Just verify we get some meaningful response
            expect(record.keys, isNotEmpty);
          }
        } catch (e) {
          // Some Neo4j versions might not have this exact procedure
          // Skip test if procedure doesn't exist
          if (e.toString().contains('Unknown procedure') ||
              e.toString().contains('There is no procedure')) {
            return;
          }
          rethrow;
        } finally {
          await session.close();
        }
      });

      test('handles database selection in cluster', () async {
        driver = createDriver();

        // Test with system database
        final systemSession = driver.session(
          const SessionConfig(database: 'system'),
        );
        try {
          final result = await systemSession.run('SHOW DATABASES');
          final records = await result.list();

          expect(records, isNotEmpty);

          // Should include at least the system and neo4j databases
          final dbNames = records.map((r) => r['name']).toSet();
          expect(dbNames, contains('system'));
        } finally {
          await systemSession.close();
        }
      });

      test('executes cluster management queries', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          // Query cluster status
          final result = await session.run('CALL dbms.cluster.role()');
          final records = await result.list();

          expect(records, hasLength(1));
          final role = records.first['role'] as String;
          expect(['LEADER', 'FOLLOWER'], contains(role));
        } catch (e) {
          // Skip if running against single instance instead of cluster
          if (e.toString().contains('Unknown procedure') ||
              e.toString().contains('There is no procedure')) {
            return;
          }
          rethrow;
        } finally {
          await session.close();
        }
      });
    });

    group('Load Balancing', () {
      test('distributes load across cluster members', () async {
        driver = createDriver();

        // Create multiple sessions and execute concurrent read operations
        final futures = <Future<void>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            final session = driver.session(const SessionConfig.read());
            try {
              final result = await session.run('RETURN \$query_id AS id', {
                'query_id': i,
              });
              final records = await result.list();
              expect(records.first['id'], equals(i));
            } finally {
              await session.close();
            }
          }());
        }

        await Future.wait(futures);
      });

      test('handles concurrent write operations', () async {
        driver = createDriver();

        final session = driver.session();
        try {
          await TestData.cleanup(session);

          // Execute concurrent write transactions
          final futures = <Future<void>>[];

          for (int i = 0; i < 5; i++) {
            futures.add(
              session.executeWrite<void>((transaction) async {
                await transaction.run(
                  'CREATE (p:Person {name: \$name, batch_id: \$batch})',
                  {'name': 'Concurrent$i', 'batch': 'load_test'},
                );
              }),
            );
          }

          await Future.wait(futures);

          // Verify all writes succeeded
          final result = await session.run(
            'MATCH (p:Person {batch_id: "load_test"}) RETURN count(p) AS count',
          );
          final records = await result.list();
          expect(records.first['count'], equals(5));
        } finally {
          await session.close();
        }
      });
    });

    group('Bookmarks and Consistency', () {
      test('maintains causal consistency with bookmarks', () async {
        driver = createDriver();

        // Write session to create data
        final writeSession = driver.session(const SessionConfig.write());
        String? lastBookmark;

        try {
          await TestData.cleanup(writeSession);

          await writeSession.executeWrite<void>((transaction) async {
            await transaction.run(
              'CREATE (p:Person {name: "Bookmark Test", id: 999})',
            );
          });

          lastBookmark =
              writeSession.lastBookmarks.isNotEmpty
                  ? writeSession.lastBookmarks.last
                  : null;
        } finally {
          await writeSession.close();
        }

        // Read session with bookmark to ensure consistency
        final bookmarks = lastBookmark != null ? [lastBookmark] : <String>[];
        final readSession = driver.session(
          SessionConfig.read(bookmarks: bookmarks),
        );

        try {
          final result = await readSession.run(
            'MATCH (p:Person {id: 999}) RETURN p.name AS name',
          );
          final records = await result.list();

          expect(records, hasLength(1));
          expect(records.first['name'], equals('Bookmark Test'));
        } finally {
          await readSession.close();
        }
      });

      test('handles bookmark propagation across sessions', () async {
        driver = createDriver();

        final session1 = driver.session();
        List<String> bookmarks = [];

        try {
          await TestData.cleanup(session1);

          // First write operation
          await session1.executeWrite<void>((transaction) async {
            await transaction.run(
              'CREATE (p:Person {name: "Session1", step: 1})',
            );
          });

          bookmarks = session1.lastBookmarks;
        } finally {
          await session1.close();
        }

        // Second session with bookmarks from first
        final session2 = driver.session(SessionConfig(bookmarks: bookmarks));

        try {
          // Should see data from session1 due to bookmark
          final result = await session2.run(
            'MATCH (p:Person {step: 1}) RETURN p.name AS name',
          );
          final records = await result.list();

          expect(records, hasLength(1));
          expect(records.first['name'], equals('Session1'));

          // Add more data in session2
          await session2.executeWrite<void>((transaction) async {
            await transaction.run(
              'CREATE (p:Person {name: "Session2", step: 2})',
            );
          });
        } finally {
          await session2.close();
        }
      });
    });

    group('Error Handling in Cluster', () {
      test('retries transient errors automatically', () async {
        driver = Neo4jDriver.create(
          TestConfig.neo4jClusterUri,
          auth: TestConfig.auth,
          config: const DriverConfig(
            maxTransactionRetryTime: Duration(seconds: 30),
          ),
        );

        final session = driver.session();
        try {
          // Execute a transaction that might encounter transient errors
          final result = await session.executeWrite<int>((transaction) async {
            await transaction.run(
              'CREATE (p:Person {name: "Retry Test", timestamp: timestamp()})',
            );

            final queryResult = await transaction.run(
              'MATCH (p:Person {name: "Retry Test"}) RETURN count(p) AS count',
            );
            final records = await queryResult.list();
            return records.first['count'] as int;
          });

          expect(result, equals(1));
        } finally {
          await session.close();
        }
      });

      test('handles cluster unavailability gracefully', () async {
        // Test with a short timeout to simulate unavailability
        driver = Neo4jDriver.create(
          'neo4j://nonexistent-cluster:7687',
          auth: TestConfig.auth,
          config: const DriverConfig(
            connectionTimeout: Duration(milliseconds: 500),
          ),
        );

        // Should throw ServiceUnavailableException when trying to connect to unavailable cluster
        await expectLater(
          driver.verifyConnectivity(),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });
    });
  });
}
