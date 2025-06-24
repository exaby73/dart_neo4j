import 'dart:io';

import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';
import '../../helpers/ssl_test_helper.dart';

void main() {
  group('SSL Connection Tests', () {
    setUpAll(() async {
      // Skip SSL tests if running in CI without SSL containers
      if (Platform.environment['SKIP_SSL_TESTS'] == 'true') {
        return;
      }
      
      // Set up SSL context to trust our test CA certificate
      try {
        if (await SSLTestHelper.areCertificatesAvailable()) {
          await SSLTestHelper.setupSSLContextForTesting();
          print('SSL context configured to trust test CA certificate');
        } else {
          print('Warning: SSL certificates not found. Run ./scripts/generate-ssl-certs.sh first.');
          return;
        }
      } catch (e) {
        print('Warning: Failed to set up SSL context: $e');
        return;
      }
      
      print('Waiting for SSL Neo4j instances to be ready...');
      try {
        await TestConfig.waitForSsl();
        await TestConfig.waitForSelfSigned();
        print('SSL Neo4j instances are ready!');
      } catch (e) {
        print('Warning: SSL instances not available, some tests will be skipped: $e');
      }
    });

    group('bolt+s:// (encrypted with certificate validation)', () {
      test('should connect successfully with valid certificate', () async {
        if (!await TestConfig.isSslAvailable()) {
          markTestSkipped('SSL Neo4j instance not available');
          return;
        }

        final driver = SSLTestHelper.createSSLDriver(
          TestConfig.boltSslUri,
          TestConfig.sslAuth,
        );

        try {
          await driver.verifyConnectivity();
          
          final session = driver.session();
          try {
            final result = await session.run('RETURN "SSL Connection Successful" AS message');
            final records = await result.list();
            final record = records.first;
            expect(record['message'], equals('SSL Connection Successful'));
          } finally {
            await session.close();
          }
        } finally {
          await driver.close();
        }
      });

      test('should perform basic CRUD operations over SSL', () async {
        if (!await TestConfig.isSslAvailable()) {
          markTestSkipped('SSL Neo4j instance not available');
          return;
        }

        final driver = SSLTestHelper.createSSLDriver(
          TestConfig.boltSslUri,
          TestConfig.sslAuth,
        );

        try {
          final session = driver.session();
          try {
            // Create
            await session.run(
              'CREATE (n:SSLTest {name: \$name, encrypted: true})',
              {'name': 'SSL Test Node'}
            );

            // Read
            final result = await session.run(
              'MATCH (n:SSLTest {name: \$name}) RETURN n.name AS name, n.encrypted AS encrypted',
              {'name': 'SSL Test Node'}
            );
            
            final records = await result.list();
            final record = records.first;
            expect(record['name'], equals('SSL Test Node'));
            expect(record['encrypted'], isTrue);

            // Update
            await session.run(
              'MATCH (n:SSLTest {name: \$name}) SET n.updated = true',
              {'name': 'SSL Test Node'}
            );

            // Delete
            final deleteResult = await session.run(
              'MATCH (n:SSLTest {name: \$name}) DELETE n RETURN count(n) AS deleted',
              {'name': 'SSL Test Node'}
            );
            
            final deleteRecords = await deleteResult.list();
            expect(deleteRecords.first['deleted'], equals(1));
          } finally {
            await session.close();
          }
        } finally {
          await driver.close();
        }
      });

      test('should handle multiple concurrent SSL connections', () async {
        if (!await TestConfig.isSslAvailable()) {
          markTestSkipped('SSL Neo4j instance not available');
          return;
        }

        final driver = SSLTestHelper.createSSLDriver(
          TestConfig.boltSslUri,
          TestConfig.sslAuth,
        );

        try {
          final futures = List.generate(5, (index) async {
            final session = driver.session();
            try {
              final result = await session.run(
                'RETURN \$connectionId AS id, "SSL" AS type',
                {'connectionId': index}
              );
              final records = await result.list();
              return records.first['id'] as int;
            } finally {
              await session.close();
            }
          });

          final results = await Future.wait(futures);
          expect(results, hasLength(5));
          expect(results, containsAll([0, 1, 2, 3, 4]));
        } finally {
          await driver.close();
        }
      });
    });

    group('bolt+ssc:// (encrypted with self-signed certificates)', () {
      test('should connect successfully with self-signed certificate', () async {
        if (!await TestConfig.isSelfSignedAvailable()) {
          markTestSkipped('Self-signed SSL Neo4j instance not available');
          return;
        }

        final driver = Neo4jDriver.create(
          TestConfig.boltSelfSignedUri,
          auth: TestConfig.sslAuth,
        );

        try {
          await driver.verifyConnectivity();
          
          final session = driver.session();
          try {
            final result = await session.run('RETURN "Self-Signed SSL Connection Successful" AS message');
            final records = await result.list();
            final record = records.first;
            expect(record['message'], equals('Self-Signed SSL Connection Successful'));
          } finally {
            await session.close();
          }
        } finally {
          await driver.close();
        }
      });

      test('should perform transactions over self-signed SSL', () async {
        if (!await TestConfig.isSelfSignedAvailable()) {
          markTestSkipped('Self-signed SSL Neo4j instance not available');
          return;
        }

        final driver = Neo4jDriver.create(
          TestConfig.boltSelfSignedUri,
          auth: TestConfig.sslAuth,
        );

        try {
          final session = driver.session();
          try {
            await session.executeWrite((tx) async {
              await tx.run(
                'CREATE (n:SelfSignedTest {name: \$name, timestamp: \$timestamp})',
                {'name': 'Transaction Test', 'timestamp': DateTime.now().millisecondsSinceEpoch}
              );
              
              await tx.run(
                'CREATE (n:SelfSignedTest {name: \$name, timestamp: \$timestamp})',
                {'name': 'Transaction Test 2', 'timestamp': DateTime.now().millisecondsSinceEpoch}
              );
            });

            final result = await session.run('MATCH (n:SelfSignedTest) RETURN count(n) AS count');
            final records = await result.list();
            expect(records.first['count'], greaterThanOrEqualTo(2));

            // Cleanup
            await session.run('MATCH (n:SelfSignedTest) DELETE n');
          } finally {
            await session.close();
          }
        } finally {
          await driver.close();
        }
      });
    });

    group('SSL Error Handling', () {
      test('should handle SSL handshake failures gracefully', () async {
        // Try to connect to a non-SSL port with SSL scheme
        final driver = Neo4jDriver.create(
          'bolt+s://localhost:7687', // This is the non-SSL port
          auth: TestConfig.auth,
        );

        try {
          await expectLater(
            driver.verifyConnectivity(),
            throwsA(isA<Neo4jException>()),
          );
        } finally {
          await driver.close();
        }
      });

      test('should throw appropriate exception for certificate validation failure', () async {
        // This test would require a SSL server with an invalid certificate
        // For now, we'll just test that self-signed fails when using bolt+s://
        if (!await TestConfig.isSelfSignedAvailable()) {
          markTestSkipped('Self-signed SSL Neo4j instance not available');
          return;
        }

        final driver = Neo4jDriver.create(
          'bolt+s://localhost:7695', // Self-signed server with strict validation
          auth: TestConfig.sslAuth,
        );

        try {
          await expectLater(
            driver.verifyConnectivity(),
            throwsA(isA<ServiceUnavailableException>()),
          );
        } finally {
          await driver.close();
        }
      });

      test('should handle connection timeout for unavailable SSL server', () async {
        final driver = Neo4jDriver.create(
          'bolt+s://localhost:9999', // Non-existent port
          auth: TestConfig.auth,
        );

        try {
          await expectLater(
            driver.verifyConnectivity(),
            throwsA(isA<Neo4jException>()),
          );
        } finally {
          await driver.close();
        }
      });
    });

    group('SSL URI Parsing Integration', () {
      test('should correctly parse and use bolt+s:// URI', () async {
        if (!await TestConfig.isSslAvailable()) {
          markTestSkipped('SSL Neo4j instance not available');
          return;
        }

        final driver = SSLTestHelper.createSSLDriver(
          'bolt+s://localhost:7694',
          BasicAuth('neo4j', 'password'),
        );

        try {
          await driver.verifyConnectivity();
          expect(driver.toString(), contains('bolt+s://'));
        } finally {
          await driver.close();
        }
      });

      test('should correctly parse and use bolt+ssc:// URI', () async {
        if (!await TestConfig.isSelfSignedAvailable()) {
          markTestSkipped('Self-signed SSL Neo4j instance not available');
          return;
        }

        final driver = Neo4jDriver.create(
          'bolt+ssc://localhost:7695',
          auth: BasicAuth('neo4j', 'password'),
        );

        try {
          await driver.verifyConnectivity();
          expect(driver.toString(), contains('bolt+ssc://'));
        } finally {
          await driver.close();
        }
      });
    });
  });
}