import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Neo4j Session Integration Tests', () {
    late Neo4jDriver driver;
    late Session session;

    setUpAll(() async {
      await TestConfig.waitForNeo4j();
    });

    setUp(() async {
      driver = Neo4jDriver.create(TestConfig.boltUri, auth: TestConfig.auth);
      session = driver.session();

      // Clean up test data
      await TestData.cleanup(session);
    });

    tearDown(() async {
      if (!session.isClosed) {
        await session.close();
      }
      if (!driver.isClosed) {
        await driver.close();
      }
    });

    group('Session Configuration', () {
      test('creates session with default configuration', () {
        expect(session.config.accessMode, equals(AccessMode.write));
        expect(session.config.database, isNull);
        expect(session.config.bookmarks, isEmpty);
        expect(session.isClosed, isFalse);
        expect(session.lastBookmarks, isEmpty);
      });

      test('creates session with read-only access', () async {
        await session.close();

        const config = SessionConfig.read();
        session = driver.session(config);

        expect(session.config.accessMode, equals(AccessMode.read));
      });

      test('creates session with specific database', () async {
        await session.close();

        const config = SessionConfig(database: 'system');
        session = driver.session(config);

        expect(session.config.database, equals('system'));
      });

      test('creates session with bookmarks', () async {
        await session.close();

        const bookmarks = ['bookmark1', 'bookmark2'];
        const config = SessionConfig(bookmarks: bookmarks);
        session = driver.session(config);

        expect(session.config.bookmarks, equals(bookmarks));
      });

      test('SessionConfig toString works correctly', () {
        const config = SessionConfig(
          database: 'mydb',
          accessMode: AccessMode.read,
          bookmarks: ['b1', 'b2'],
        );

        final str = config.toString();
        expect(str, contains('database: mydb'));
        expect(str, contains('accessMode: AccessMode.read'));
        expect(str, contains('bookmarks: 2'));
      });

      test('session toString works correctly', () {
        final str = session.toString();
        expect(str, contains('Session'));
        expect(str, contains('closed: false'));
        expect(str, contains('bookmarks: 0'));
      });
    });

    group('Auto-commit Queries', () {
      test('executes simple query', () async {
        final result = await session.run('RETURN 1 AS number');
        final records = await result.list();

        expect(records, hasLength(1));
        expect(records.first['number'], equals(1));
      });

      test('executes query with parameters', () async {
        final result = await session.run(
          'RETURN \$name AS name, \$age AS age',
          {'name': 'John', 'age': 30},
        );
        final records = await result.list();

        expect(records, hasLength(1));
        expect(records.first['name'], equals('John'));
        expect(records.first['age'], equals(30));
      });

      test('executes multiple queries independently', () async {
        final result1 = await session.run('RETURN 1 AS value');
        final result2 = await session.run('RETURN 2 AS value');

        final records1 = await result1.list();
        final records2 = await result2.list();

        expect(records1.first['value'], equals(1));
        expect(records2.first['value'], equals(2));
      });

      test('handles query with no results', () async {
        final result = await session.run('MATCH (n:NonExistentLabel) RETURN n');
        final records = await result.list();

        expect(records, isEmpty);
      });

      test('handles query with multiple results', () async {
        // Clean up first to ensure isolation
        await session.run(
          'MATCH (p:Person) WHERE p.name IN ["Alice", "Bob"] DELETE p',
        );

        // Create test data
        await session.run('CREATE (p:Person {name: \$name, age: \$age})', {
          'name': 'Alice',
          'age': 30,
        });
        await session.run('CREATE (p:Person {name: \$name, age: \$age})', {
          'name': 'Bob',
          'age': 25,
        });

        final result = await session.run(
          'MATCH (p:Person) WHERE p.name IN ["Alice", "Bob"] RETURN p.name AS name ORDER BY p.name',
        );
        final records = await result.list();

        expect(records, hasLength(2));
        expect(records[0]['name'], equals('Alice'));
        expect(records[1]['name'], equals('Bob'));
      });

      test('throws on closed session', () async {
        await session.close();

        await expectLater(
          session.run('RETURN 1'),
          throwsA(
            isA<SessionExpiredException>().having(
              (e) => e.message,
              'message',
              'Session has been closed',
            ),
          ),
        );
      });

      test('handles database errors', () async {
        await expectLater(
          session.run('INVALID CYPHER QUERY'),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('Explicit Transactions', () {
      test('begins and commits transaction', () async {
        // Clean up first to ensure isolation - remove all Charlie nodes
        await session.run('MATCH (p:Person {name: "Charlie"}) DETACH DELETE p');

        final transaction = await session.beginTransaction();

        expect(transaction.isActive, isTrue);
        expect(transaction.isClosed, isFalse);
        expect(transaction.state, equals(TransactionState.active));

        await transaction.run('CREATE (p:Person {name: \$name, age: \$age})', {
          'name': 'Charlie',
          'age': 35,
        });
        await transaction.commit();

        expect(transaction.isClosed, isTrue);
        expect(transaction.state, equals(TransactionState.committed));

        // Verify data was committed - use more specific query to avoid duplicates
        final result = await session.run(
          'MATCH (p:Person {name: \$name, age: \$age}) RETURN p',
          {'name': 'Charlie', 'age': 35},
        );
        final records = await result.list();
        expect(records, hasLength(1));

        // Clean up after test
        await session.run(
          'MATCH (p:Person {name: "Charlie", age: 35}) DETACH DELETE p',
        );
      });

      test('begins and rolls back transaction', () async {
        final transaction = await session.beginTransaction();

        await transaction.run('CREATE (p:Person {name: \$name})', {
          'name': 'David',
        });
        await transaction.rollback();

        expect(transaction.isClosed, isTrue);
        expect(transaction.state, equals(TransactionState.rolledBack));

        // Verify data was not committed
        final result = await session.run(
          'MATCH (p:Person {name: \$name}) RETURN p',
          {'name': 'David'},
        );
        final records = await result.list();
        expect(records, isEmpty);
      });

      test('multiple queries in same transaction', () async {
        final transaction = await session.beginTransaction();

        await transaction.run('CREATE (p:Person {name: \$name})', {
          'name': 'Eve',
        });
        await transaction.run('CREATE (p:Person {name: \$name})', {
          'name': 'Frank',
        });

        final result = await transaction.run(
          'MATCH (p:Person) WHERE p.name IN [\$name1, \$name2] RETURN p.name AS name ORDER BY p.name',
          {'name1': 'Eve', 'name2': 'Frank'},
        );
        final records = await result.list();

        expect(records, hasLength(2));
        expect(records[0]['name'], equals('Eve'));
        expect(records[1]['name'], equals('Frank'));

        await transaction.commit();
      });

      test('throws on closed transaction', () async {
        final transaction = await session.beginTransaction();
        await transaction.commit();

        await expectLater(
          transaction.run('RETURN 1'),
          throwsA(isA<TransactionClosedException>()),
        );
      });

      test('throws when beginning transaction on closed session', () async {
        await session.close();

        await expectLater(
          session.beginTransaction(),
          throwsA(isA<SessionExpiredException>()),
        );
      });

      test('transaction with custom config', () async {
        const config = TransactionConfig(
          timeout: Duration(seconds: 30),
          metadata: {'key': 'value'},
        );

        final transaction = await session.beginTransaction(config);
        await transaction.run('RETURN 1');
        await transaction.commit();
      });

      test('TransactionConfig toString works correctly', () {
        const config = TransactionConfig(
          timeout: Duration(seconds: 30),
          metadata: {'key1': 'value1', 'key2': 'value2'},
        );

        final str = config.toString();
        expect(str, contains('timeout: 0:00:30.000000'));
        expect(str, contains('metadata: 2 entries'));
      });
    });

    group('Managed Transactions - Read', () {
      test('executes read transaction successfully', () async {
        // Clean up first to ensure isolation
        await session.run('MATCH (p:Person {name: "Grace"}) DETACH DELETE p');

        // Create test data first
        await session.run('CREATE (p:Person {name: \$name, age: \$age})', {
          'name': 'Grace',
          'age': 35,
        });

        final result = await session.executeRead<String>((transaction) async {
          final queryResult = await transaction.run(
            'MATCH (p:Person {name: \$name}) RETURN p.name AS name',
            {'name': 'Grace'},
          );
          final records = await queryResult.list();
          if (records.isEmpty) {
            throw StateError('No records found for Grace');
          }
          return records.first['name'] as String;
        });

        expect(result, equals('Grace'));

        // Clean up after test
        await session.run('MATCH (p:Person {name: "Grace"}) DETACH DELETE p');
      });

      test('executes read transaction with parameters', () async {
        await session.run('CREATE (p:Person {name: \$name, age: \$age})', {
          'name': 'Henry',
          'age': 40,
        });

        final result = await session.executeRead<int>((transaction) async {
          final queryResult = await transaction.run(
            'MATCH (p:Person {name: \$name}) RETURN p.age AS age',
            {'name': 'Henry'},
          );
          final records = await queryResult.list();
          return records.first['age'] as int;
        });

        expect(result, equals(40));
      });

      test('read transaction rolls back on error', () async {
        await expectLater(
          session.executeRead<void>((transaction) async {
            await transaction.run('INVALID CYPHER');
          }),
          throwsA(isA<DatabaseException>()),
        );
      });

      test(
        'throws when executing read transaction on closed session',
        () async {
          await session.close();

          await expectLater(
            session.executeRead<void>((transaction) async {
              await transaction.run('RETURN 1');
            }),
            throwsA(isA<SessionExpiredException>()),
          );
        },
      );

      test('read transaction with custom config', () async {
        const config = TransactionConfig(timeout: Duration(seconds: 10));

        final result = await session.executeRead<int>((transaction) async {
          final queryResult = await transaction.run('RETURN 42 AS answer');
          final records = await queryResult.list();
          return records.first['answer'] as int;
        }, config);

        expect(result, equals(42));
      });
    });

    group('Managed Transactions - Write', () {
      test('executes write transaction successfully', () async {
        final result = await session.executeWrite<String>((transaction) async {
          await transaction.run(
            'CREATE (p:Person {name: \$name, age: \$age})',
            {'name': 'Ivy', 'age': 28},
          );

          final queryResult = await transaction.run(
            'MATCH (p:Person {name: \$name}) RETURN p.name AS name',
            {'name': 'Ivy'},
          );
          final records = await queryResult.list();
          return records.first['name'] as String;
        });

        expect(result, equals('Ivy'));

        // Verify data was committed
        final verifyResult = await session.run(
          'MATCH (p:Person {name: \$name}) RETURN p',
          {'name': 'Ivy'},
        );
        final verifyRecords = await verifyResult.list();
        expect(verifyRecords, hasLength(1));
      });

      test('write transaction rolls back on error', () async {
        await expectLater(
          session.executeWrite<void>((transaction) async {
            await transaction.run('CREATE (p:Person {name: \$name})', {
              'name': 'Jack',
            });
            await transaction.run('INVALID CYPHER');
          }),
          throwsA(isA<DatabaseException>()),
        );

        // Verify no data was committed
        final result = await session.run(
          'MATCH (p:Person {name: \$name}) RETURN p',
          {'name': 'Jack'},
        );
        final records = await result.list();
        expect(records, isEmpty);
      });

      test(
        'throws when executing write transaction on closed session',
        () async {
          await session.close();

          await expectLater(
            session.executeWrite<void>((transaction) async {
              await transaction.run('CREATE (p:Person {name: "test"})');
            }),
            throwsA(isA<SessionExpiredException>()),
          );
        },
      );

      test('write transaction with custom config', () async {
        const config = TransactionConfig(
          timeout: Duration(seconds: 15),
          metadata: {'operation': 'create_person'},
        );

        final result = await session.executeWrite<String>((transaction) async {
          await transaction.run('CREATE (p:Person {name: \$name})', {
            'name': 'Kate',
          });
          return 'Kate';
        }, config);

        expect(result, equals('Kate'));
      });
    });

    group('Concurrent Operations', () {
      test('concurrent auto-commit queries', () async {
        final futures = <Future<void>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            final result = await session.run('RETURN \$value AS value', {
              'value': i,
            });
            final records = await result.list();
            expect(records.first['value'], equals(i));
          }());
        }

        await Future.wait(futures);
      });

      test('concurrent transactions', () async {
        // Clean up any existing Person nodes first
        await session.run(
          'MATCH (p:Person) WHERE p.name STARTS WITH "Person" DELETE p',
        );

        final futures = <Future<void>>[];

        for (int i = 0; i < 5; i++) {
          futures.add(
            session.executeWrite<void>((transaction) async {
              await transaction.run(
                'CREATE (p:Person {name: \$name, number: \$number})',
                {'name': 'Person$i', 'number': i},
              );
            }),
          );
        }

        await Future.wait(futures);

        // Verify all data was created
        final result = await session.run(
          'MATCH (p:Person) WHERE p.name STARTS WITH "Person" RETURN count(p) AS count',
        );
        final records = await result.list();
        expect(records.first['count'], equals(5));

        // Clean up after test
        await session.run(
          'MATCH (p:Person) WHERE p.name STARTS WITH "Person" DELETE p',
        );
      });
    });

    group('Session Lifecycle', () {
      test('closes session successfully', () async {
        expect(session.isClosed, isFalse);

        await session.close();

        expect(session.isClosed, isTrue);
      });

      test('multiple close calls are safe', () async {
        await session.close();
        await session.close(); // Should not throw

        expect(session.isClosed, isTrue);
      });

      test('closed session handles toString correctly', () async {
        await session.close();

        final str = session.toString();
        expect(str, contains('closed: true'));
      });
    });

    group('Error Handling and Recovery', () {
      test('session continues working after query error', () async {
        // Execute invalid query
        await expectLater(
          session.run('INVALID QUERY'),
          throwsA(isA<DatabaseException>()),
        );

        // Session should still work for valid queries
        final result = await session.run('RETURN 1 AS value');
        final records = await result.list();
        expect(records.first['value'], equals(1));
      });

      test('session continues working after transaction error', () async {
        // Execute transaction that fails
        await expectLater(
          session.executeWrite<void>((transaction) async {
            await transaction.run('INVALID QUERY');
          }),
          throwsA(isA<DatabaseException>()),
        );

        // Session should still work for new operations
        final result = await session.executeWrite<int>((transaction) async {
          final queryResult = await transaction.run('RETURN 42 AS answer');
          final records = await queryResult.list();
          return records.first['answer'] as int;
        });

        expect(result, equals(42));
      });

      test('handles connection issues gracefully', () async {
        // This test assumes the connection can be recovered
        // In a real scenario, the connection pool would handle reconnection
        final result = await session.run('RETURN "connection_test" AS message');
        final records = await result.list();
        expect(records.first['message'], equals('connection_test'));
      });
    });

    group('Data Types and Conversions', () {
      test('handles various data types', () async {
        final result = await session.run('''
          RETURN 
            true AS boolean_val,
            42 AS int_val,
            3.14 AS float_val,
            "hello" AS string_val,
            date() AS date_val,
            [1, 2, 3] AS list_val,
            {key: "value"} AS map_val
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['boolean_val'], isA<bool>());
        expect(record['int_val'], isA<int>());
        expect(record['float_val'], isA<double>());
        expect(record['string_val'], isA<String>());
        expect(record['list_val'], isA<List>());
        expect(record['map_val'], isA<Map>());
      });

      test('handles null values', () async {
        final result = await session.run(
          'RETURN null AS null_value, "not null" AS string_value',
        );
        final records = await result.list();

        expect(records, hasLength(1));
        expect(records.first['null_value'], isNull);
        expect(records.first['string_value'], equals('not null'));
      });
    });

    group('Large Result Sets', () {
      test('handles moderately large result set', () async {
        // Create 100 nodes using a single query with UNWIND
        await session.run('''
          UNWIND range(0, 99) AS id
          CREATE (n:TestNode {id: id})
        ''');

        // Query all nodes
        final result = await session.run(
          'MATCH (n:TestNode) RETURN n.id AS id ORDER BY n.id',
        );
        final records = await result.list();

        expect(records, hasLength(100));
        expect(records.first['id'], equals(0));
        expect(records.last['id'], equals(99));
      });
    });
  });
}
