import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_utils.dart';

void main() {
  group('Performance Tests', () {
    late Neo4jDriver driver;
    late Session session;

    setUpAll(() async {
      await TestConfig.waitForSingle();

      driver = Neo4jDriver.create(TestConfig.boltUri, auth: TestConfig.auth);

      session = driver.session();
    });

    tearDownAll(() async {
      await TestData.cleanup(session);
      await session.close();
      await driver.close();
    });

    group('query performance', () {
      test('should handle sequential queries efficiently', () async {
        await TestData.createSampleData(session);

        final stats = await TestUtils.measurePerformance(() async {
          final result = await session.run('MATCH (n:Person) RETURN n.name');
          await result.list();
        }, 100);

        print('Sequential queries: $stats');

        // Should complete 100 queries in reasonable time
        expect(stats.average.inMilliseconds, lessThan(100));
        expect(stats.operationsPerSecond, greaterThan(10));
      });

      test(
        'should handle large result sets efficiently',
        () async {
          await TestData.cleanup(session);
          await TestData.createLargeDataset(session, nodeCount: 1000);

          // Verify data was created before proceeding
          var countResult = await session.run(
            'MATCH (n:TestNode) RETURN count(n) as count',
          );
          var countRecord = await countResult.single();
          var actualCount = countRecord['count'] as int;
          print('Created $actualCount TestNode records');

          final duration = await TestUtils.measureTime(() async {
            final result = await session.run('MATCH (n:TestNode) RETURN n');
            final records = await result.list();
            expect(records.length, equals(actualCount));
          });

          print('Large result set query: ${duration.inMilliseconds}ms');

          // Should handle records in reasonable time (increased timeout)
          expect(duration.inSeconds, lessThan(30));

          await TestData.cleanup(session);
        },
        timeout: Timeout(Duration(minutes: 3)),
      );

      test('should handle parameterized queries efficiently', () async {
        await TestData.cleanup(session);
        await TestData.createLargeDataset(session, nodeCount: 500);

        final stats = await TestUtils.measurePerformance(() async {
          final id = TestUtils.randomInt(0, 499);
          final result = await session.run(
            'MATCH (n:TestNode {id: \$id}) RETURN n',
            {'id': id},
          );
          await result.list();
        }, 200);

        print('Parameterized queries: $stats');

        // Parameterized queries should be fast
        expect(stats.average.inMilliseconds, lessThan(50));
        expect(stats.operationsPerSecond, greaterThan(20));

        await TestData.cleanup(session);
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent sessions', () async {
        await TestData.createSampleData(session);

        final duration = await TestUtils.measureTime(() async {
          final futures = <Future<void>>[];

          for (int i = 0; i < 50; i++) {
            futures.add(_performSessionWork(driver));
          }

          await Future.wait(futures);
        });

        print('50 concurrent sessions: ${duration.inMilliseconds}ms');

        // Should handle concurrent sessions without excessive delay
        expect(duration.inSeconds, lessThan(10));
      });

      test('should handle concurrent queries in single session', () async {
        await TestData.createSampleData(session);

        final duration = await TestUtils.measureTime(() async {
          final futures = <Future<void>>[];

          for (int i = 0; i < 20; i++) {
            futures.add(_performQuery(session));
          }

          await Future.wait(futures);
        });

        print('20 concurrent queries: ${duration.inMilliseconds}ms');

        // Concurrent queries should complete efficiently
        expect(duration.inSeconds, lessThan(5));
      });
    });

    group('memory efficiency', () {
      test(
        'should handle streaming large results',
        () async {
          // Clean up first to ensure clean state
          await TestData.cleanup(session);

          // Use a smaller dataset to avoid timeout issues
          await TestData.createLargeDataset(session, nodeCount: 500);

          final duration = await TestUtils.measureTime(() async {
            final result = await session.run(
              'MATCH (n:TestNode) RETURN n ORDER BY n.id',
            );
            int count = 0;

            await for (final record in result.records()) {
              // Check if we have a node value and handle type conversion
              final nodeValue = record['n'];
              expect(nodeValue, isNotNull);
              count++;
            }

            expect(count, equals(500));
          });

          print('Streaming 500 records: ${duration.inMilliseconds}ms');

          // Streaming should be memory efficient and reasonably fast
          expect(duration.inSeconds, lessThan(10));

          // Clean up after the test
          await TestData.cleanup(session);
        },
        timeout: Timeout(Duration(minutes: 3)),
      );

      test('should handle memory pressure', () async {
        await TestData.createSampleData(session);

        await TestUtils.memoryPressureTest(() async {
          final result = await session.run('MATCH (n:Person) RETURN n');
          await result.list();
        }, pressureMB: 50);

        // Should complete without memory issues
      });
    });

    group('transaction performance', () {
      test('should handle transaction overhead efficiently', () async {
        await TestData.cleanup(session);

        // Compare auto-commit vs explicit transaction
        final autoCommitStats = await TestUtils.measurePerformance(() async {
          await session.run('CREATE (n:Test {id: rand()})');
        }, 50);

        final transactionStats = await TestUtils.measurePerformance(() async {
          await session.executeWrite((tx) async {
            await tx.run('CREATE (n:Test {id: rand()})');
          });
        }, 50);

        print('Auto-commit: $autoCommitStats');
        print('Transaction: $transactionStats');

        // Both should be reasonably fast
        expect(autoCommitStats.average.inMilliseconds, lessThan(200));
        expect(transactionStats.average.inMilliseconds, lessThan(300));

        await TestData.cleanup(session);
      });

      test('should handle batch operations in transactions', () async {
        await TestData.cleanup(session);

        final duration = await TestUtils.measureTime(() async {
          await session.executeWrite((tx) async {
            for (int i = 0; i < 100; i++) {
              await tx.run('CREATE (n:BatchTest {id: \$id})', {'id': i});
            }
          });
        });

        print(
          'Batch 100 operations in transaction: ${duration.inMilliseconds}ms',
        );

        // Batch operations should be efficient
        expect(duration.inSeconds, lessThan(5));

        // Verify all nodes were created
        final result = await session.run(
          'MATCH (n:BatchTest) RETURN count(n) as count',
        );
        final count = (await result.single())['count'];
        expect(count, equals(100));

        await TestData.cleanup(session);
      });
    });

    group('stress testing', () {
      test('should handle sustained load', () async {
        await TestData.createSampleData(session);

        final duration = Duration(seconds: 10);
        var operationCount = 0;

        await TestUtils.stressTest(
          () async {
            await session.run('MATCH (n:Person) RETURN count(n)');
            operationCount++;
          },
          5,
          duration,
        );

        print(
          'Sustained load: $operationCount operations in ${duration.inSeconds}s',
        );
        print('Rate: ${operationCount / duration.inSeconds} ops/sec');

        // Should maintain reasonable throughput under sustained load
        expect(operationCount / duration.inSeconds, greaterThan(10));
      });
    });
  });
}

Future<void> _performSessionWork(Neo4jDriver driver) async {
  final session = driver.session();
  try {
    final result = await session.run('MATCH (n:Person) RETURN n.name LIMIT 1');
    await result.list();
  } finally {
    await session.close();
  }
}

Future<void> _performQuery(Session session) async {
  final result = await session.run('MATCH (n:Person) RETURN count(n) as count');
  await result.single();
}
