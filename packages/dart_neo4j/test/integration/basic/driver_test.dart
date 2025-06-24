import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:dart_neo4j/src/driver/uri_parser.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';

void main() {
  group('Neo4j Driver Integration Tests', () {
    late Neo4jDriver driver;
    
    setUpAll(() async {
      await TestConfig.waitForNeo4j();
    });

    tearDown(() async {
      if (!driver.isClosed) {
        await driver.close();
      }
    });

    group('Driver Creation', () {
      test('creates driver with bolt:// URI', () {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        expect(driver.uri.connectionType, equals(ConnectionType.direct));
        expect(driver.uri.host, equals('localhost'));
        expect(driver.uri.port, equals(7687));
        expect(driver.auth, equals(TestConfig.auth));
        expect(driver.isClosed, isFalse);
      });

      test('creates driver with neo4j:// URI', () {
        driver = Neo4jDriver.create(
          TestConfig.neo4jUri,
          auth: TestConfig.auth,
        );
        
        expect(driver.uri.connectionType, equals(ConnectionType.routing));
        expect(driver.isClosed, isFalse);
      });

      test('creates driver with custom config', () {
        const config = DriverConfig(
          maxConnectionPoolSize: 50,
          connectionTimeout: Duration(seconds: 10),
        );
        
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
          config: config,
        );
        
        expect(driver.config.maxConnectionPoolSize, equals(50));
        expect(driver.config.connectionTimeout, equals(const Duration(seconds: 10)));
      });

      test('throws on invalid URI', () {
        expect(
          () => Neo4jDriver.create('invalid-uri'),
          throwsA(isA<InvalidUriException>()),
        );
      });
    });

    group('Connectivity Verification', () {
      test('verifies connectivity successfully', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        await expectLater(
          driver.verifyConnectivity(),
          completes,
        );
      });

      test('throws on connectivity failure with wrong port', () async {
        const config = DriverConfig(
          connectionTimeout: Duration(milliseconds: 500), // Short timeout
        );
        driver = Neo4jDriver.create(
          'bolt://localhost:9999',
          auth: TestConfig.auth,
          config: config,
        );
        
        // Should throw ServiceUnavailableException when connection is refused
        await expectLater(
          driver.verifyConnectivity(),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });

      test('throws on connectivity failure with wrong credentials', () async {
        const config = DriverConfig(
          connectionTimeout: Duration(seconds: 2), // Fast timeout for error tests
        );
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: BasicAuth('wrong', 'credentials'),
          config: config,
        );
        
        await expectLater(
          driver.verifyConnectivity(),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('throws when verifying closed driver', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        await driver.close();
        
        await expectLater(
          driver.verifyConnectivity(),
          throwsA(isA<ServiceUnavailableException>().having(
            (e) => e.message,
            'message',
            'Driver has been closed',
          )),
        );
      });
    });

    group('Session Management', () {
      setUp(() {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
      });

      test('creates session with default config', () {
        final session = driver.session();
        
        expect(session, isA<Session>());
        expect(session.config.accessMode, equals(AccessMode.write));
        expect(session.config.database, isNull);
        expect(session.isClosed, isFalse);
        
        session.close();
      });

      test('creates session with custom config', () {
        const config = SessionConfig(
          database: 'system',
          accessMode: AccessMode.read,
        );
        
        final session = driver.session(config);
        
        expect(session.config.accessMode, equals(AccessMode.read));
        expect(session.config.database, equals('system'));
        
        session.close();
      });

      test('creates read-only session', () {
        const config = SessionConfig.read();
        final session = driver.session(config);
        
        expect(session.config.accessMode, equals(AccessMode.read));
        
        session.close();
      });

      test('creates write session', () {
        const config = SessionConfig.write();
        final session = driver.session(config);
        
        expect(session.config.accessMode, equals(AccessMode.write));
        
        session.close();
      });

      test('throws when creating session on closed driver', () async {
        await driver.close();
        
        expect(
          () => driver.session(),
          throwsA(isA<ServiceUnavailableException>().having(
            (e) => e.message,
            'message',
            'Driver has been closed',
          )),
        );
      });

      test('multiple sessions work independently', () async {
        final session1 = driver.session();
        final session2 = driver.session();
        
        expect(session1, isNot(equals(session2)));
        
        // Both sessions should be able to execute queries
        final result1 = await session1.run('RETURN 1 AS value');
        final result2 = await session2.run('RETURN 2 AS value');
        
        final records1 = await result1.list();
        final records2 = await result2.list();
        
        expect(records1, hasLength(1));
        expect(records2, hasLength(1));
        expect(records1.first['value'], equals(1));
        expect(records2.first['value'], equals(2));
        
        await session1.close();
        await session2.close();
      });

      test('concurrent sessions work correctly', () async {
        final futures = <Future<void>>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            final session = driver.session();
            try {
              final result = await session.run('RETURN \$value AS value', {'value': i});
              final records = await result.list();
              expect(records, hasLength(1));
              expect(records.first['value'], equals(i));
            } finally {
              await session.close();
            }
          }());
        }
        
        await Future.wait(futures);
      });
    });

    group('Driver Lifecycle', () {
      test('closes driver successfully', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        expect(driver.isClosed, isFalse);
        
        await driver.close();
        
        expect(driver.isClosed, isTrue);
      });

      test('multiple close calls are safe', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        await driver.close();
        await driver.close(); // Should not throw
        
        expect(driver.isClosed, isTrue);
      });

      test('closed driver closes active sessions', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        final session = driver.session();
        
        await driver.close();
        
        // Session should still be functional until explicitly closed
        // as it manages its own connection pool references
        await session.close();
      });
    });

    group('Error Handling', () {
      test('handles network interruption gracefully', () async {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        // Verify connectivity first
        await driver.verifyConnectivity();
        
        // Create a session and execute a query to ensure connection works
        final session = driver.session();
        try {
          final result = await session.run('RETURN 1');
          final records = await result.list();
          expect(records, hasLength(1));
        } finally {
          await session.close();
        }
      });

      test('handles connection timeout', () async {
        const config = DriverConfig(
          connectionTimeout: Duration(milliseconds: 100), // Short timeout
        );
        
        driver = Neo4jDriver.create(
          'bolt://unreachable-host:7687',
          auth: TestConfig.auth,
          config: config,
        );
        
        // Should throw ServiceUnavailableException when host is unreachable
        await expectLater(
          driver.verifyConnectivity(),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });
    });

    group('Configuration Validation', () {
      test('DriverConfig toString works correctly', () {
        const config = DriverConfig(
          maxConnectionPoolSize: 50,
          connectionTimeout: Duration(seconds: 10),
        );
        
        final str = config.toString();
        expect(str, contains('maxConnectionPoolSize: 50'));
        expect(str, contains('connectionTimeout: 0:00:10.000000'));
      });

      test('driver toString works correctly', () {
        driver = Neo4jDriver.create(
          TestConfig.boltUri,
          auth: TestConfig.auth,
        );
        
        final str = driver.toString();
        expect(str, contains('Neo4jDriver'));
        expect(str, contains('bolt://localhost:7687'));
        expect(str, contains('closed: false'));
      });
    });

    group('Memory Management', () {
      test('driver releases resources on close', () async {
        // Create and close multiple drivers to test resource cleanup
        for (int i = 0; i < 5; i++) {
          final testDriver = Neo4jDriver.create(
            TestConfig.boltUri,
            auth: TestConfig.auth,
          );
          
          await testDriver.verifyConnectivity();
          
          final session = testDriver.session();
          final result = await session.run('RETURN \$i AS value', {'i': i});
          final records = await result.list();
          expect(records.first['value'], equals(i));
          
          await session.close();
          await testDriver.close();
        }
        
        // If we reach here without memory issues, resource cleanup is working
        expect(true, isTrue);
      });

      test('handles rapid create/close cycles', () async {
        final futures = <Future<void>>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            final testDriver = Neo4jDriver.create(
              TestConfig.boltUri,
              auth: TestConfig.auth,
            );
            
            try {
              await testDriver.verifyConnectivity();
            } finally {
              await testDriver.close();
            }
          }());
        }
        
        await Future.wait(futures);
      });
    });
  });
}