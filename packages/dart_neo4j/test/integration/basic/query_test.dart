import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Neo4j Query Integration Tests', () {
    late Neo4jDriver driver;
    late Session session;

    setUpAll(() async {
      await TestConfig.waitForNeo4j();
    });

    setUp(() async {
      driver = Neo4jDriver.create(TestConfig.boltUri, auth: TestConfig.auth);
      session = driver.session();

      // Clean up and prepare test data
      await TestData.cleanup(session);
      await TestData.createSampleData(session);
    });

    tearDown(() async {
      await TestData.cleanup(session);
      if (!session.isClosed) {
        await session.close();
      }
      if (!driver.isClosed) {
        await driver.close();
      }
    });

    group('CRUD Operations', () {
      test('CREATE - creates nodes with properties', () async {
        final result = await session.run(
          '''
          CREATE (p:Person {name: \$name, age: \$age, email: \$email}) 
          RETURN p.name AS name, p.age AS age, p.email AS email
        ''',
          {'name': 'John Doe', 'age': 35, 'email': 'john.doe@example.com'},
        );

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['name'], equals('John Doe'));
        expect(record['age'], equals(35));
        expect(record['email'], equals('john.doe@example.com'));
      });

      test('CREATE - creates relationships', () async {
        // Create nodes first with unique names
        await session.run(
          'CREATE (a:Person {name: "TestAlice"}), (b:Person {name: "TestBob"})',
        );

        // Create relationship
        final result = await session.run(
          '''
          MATCH (a:Person {name: "TestAlice"}), (b:Person {name: "TestBob"})
          CREATE (a)-[r:KNOWS {since: \$since}]->(b)
          RETURN type(r) AS relationship_type, r.since AS since
        ''',
          {'since': '2020-01-01'},
        );

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['relationship_type'], equals('KNOWS'));
        expect(records.first['since'], equals('2020-01-01'));
      });

      test('READ - matches nodes by properties', () async {
        final result = await session.run(
          '''
          MATCH (p:Person) 
          WHERE p.age > \$minAge 
          RETURN p.name AS name, p.age AS age 
          ORDER BY p.age
        ''',
          {'minAge': 25},
        );

        final records = await result.list();
        expect(records.length, greaterThan(0));

        // Verify results are ordered by age
        for (int i = 1; i < records.length; i++) {
          final prevAge = records[i - 1]['age'] as int;
          final currentAge = records[i]['age'] as int;
          expect(currentAge, greaterThanOrEqualTo(prevAge));
        }
      });

      test('READ - matches relationships with patterns', () async {
        final result = await session.run('''
          MATCH (a:Person)-[r:WORKS_FOR]->(c:Company)
          RETURN a.name AS person_name, c.name AS company_name, r.role AS position
          ORDER BY a.name
        ''');

        final records = await result.list();
        expect(records.length, greaterThan(0));

        for (final record in records) {
          expect(record['person_name'], isA<String>());
          expect(record['company_name'], isA<String>());
          expect(record['position'], isA<String>());
        }
      });

      test('UPDATE - sets node properties', () async {
        await session.run('CREATE (p:Person {name: "Test Person", age: 25})');

        final result = await session.run(
          '''
          MATCH (p:Person {name: "Test Person"})
          SET p.age = \$newAge, p.updated = \$timestamp
          RETURN p.name AS name, p.age AS age, p.updated AS updated
        ''',
          {'newAge': 26, 'timestamp': DateTime.now().millisecondsSinceEpoch},
        );

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['age'], equals(26));
        expect(records.first['updated'], isA<int>());
      });

      test('UPDATE - updates relationship properties', () async {
        await session.run('''
          CREATE (a:Person {name: "UpdateAlice"})-[r:KNOWS {since: "2020"}]->(b:Person {name: "UpdateBob"})
        ''');

        final result = await session.run(
          '''
          MATCH (a:Person {name: "UpdateAlice"})-[r:KNOWS]->(b:Person {name: "UpdateBob"})
          SET r.since = \$newSince, r.strength = \$strength
          RETURN r.since AS since, r.strength AS strength
        ''',
          {'newSince': '2021', 'strength': 'strong'},
        );

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['since'], equals('2021'));
        expect(records.first['strength'], equals('strong'));
      });

      test('DELETE - removes nodes', () async {
        await session.run('CREATE (p:TempPerson {name: "To Delete"})');

        // Verify node exists
        var result = await session.run(
          'MATCH (p:TempPerson {name: "To Delete"}) RETURN count(p) AS count',
        );
        var records = await result.list();
        expect(records.first['count'], equals(1));

        // Delete node
        await session.run('MATCH (p:TempPerson {name: "To Delete"}) DELETE p');

        // Verify node is deleted
        result = await session.run(
          'MATCH (p:TempPerson {name: "To Delete"}) RETURN count(p) AS count',
        );
        records = await result.list();
        expect(records.first['count'], equals(0));
      });

      test('DELETE - removes relationships', () async {
        // Clean up first and create specific test nodes
        await session.run(
          'MATCH (a:Person {name: "TestAlice"}), (b:Person {name: "TestBob"}) DETACH DELETE a, b',
        );

        await session.run('''
          CREATE (a:Person {name: "TestAlice"}), (b:Person {name: "TestBob"})
          CREATE (a)-[r:TEMP_REL]->(b)
        ''');

        // Verify relationship exists
        var result = await session.run('''
          MATCH (a:Person {name: "TestAlice"})-[r:TEMP_REL]->(b:Person {name: "TestBob"}) 
          RETURN count(r) AS count
        ''');
        var records = await result.list();
        expect(records.first['count'], equals(1));

        // Delete relationship
        await session.run('''
          MATCH (a:Person {name: "TestAlice"})-[r:TEMP_REL]->(b:Person {name: "TestBob"}) 
          DELETE r
        ''');

        // Verify relationship is deleted
        result = await session.run('''
          MATCH (a:Person {name: "TestAlice"})-[r:TEMP_REL]->(b:Person {name: "TestBob"}) 
          RETURN count(r) AS count
        ''');
        records = await result.list();
        expect(records.first['count'], equals(0));

        // Clean up test nodes
        await session.run(
          'MATCH (a:Person {name: "TestAlice"}), (b:Person {name: "TestBob"}) DELETE a, b',
        );
      });
    });

    group('Complex Queries', () {
      test('executes multi-step query with multiple MATCH clauses', () async {
        final result = await session.run('''
          MATCH (p:Person)-[:WORKS_FOR]->(c:Company)
          MATCH (p)-[:LIVES_IN]->(city:City)
          RETURN p.name AS person, c.name AS company, city.name AS city
          ORDER BY p.name
          LIMIT 5
        ''');

        final records = await result.list();
        expect(records.length, lessThanOrEqualTo(5));

        for (final record in records) {
          expect(record['person'], isA<String>());
          expect(record['company'], isA<String>());
          expect(record['city'], isA<String>());
        }
      });

      test('executes aggregation query', () async {
        final result = await session.run('''
          MATCH (p:Person)-[:WORKS_FOR]->(c:Company)
          RETURN c.name AS company, count(p) AS employee_count, avg(p.age) AS avg_age
          ORDER BY employee_count DESC
        ''');

        final records = await result.list();
        expect(records.length, greaterThan(0));

        for (final record in records) {
          expect(record['company'], isA<String>());
          expect(record['employee_count'], isA<int>());
          expect(record['avg_age'], isA<num>());
        }
      });

      test('executes query with OPTIONAL MATCH', () async {
        final result = await session.run('''
          MATCH (p:Person)
          OPTIONAL MATCH (p)-[:HAS_HOBBY]->(h:Hobby)
          RETURN p.name AS person, h.name AS hobby
          ORDER BY p.name
          LIMIT 10
        ''');

        final records = await result.list();
        expect(records.length, lessThanOrEqualTo(10));

        for (final record in records) {
          expect(record['person'], isA<String>());
          // hobby can be null due to OPTIONAL MATCH
        }
      });

      test('executes query with UNION', () async {
        final result = await session.run('''
          MATCH (p:Person) RETURN p.name AS name, "Person" AS type
          UNION
          MATCH (c:Company) RETURN c.name AS name, "Company" AS type
          ORDER BY name
          LIMIT 10
        ''');

        final records = await result.list();
        expect(records.length, lessThanOrEqualTo(10));

        for (final record in records) {
          expect(record['name'], isA<String>());
          expect(record['type'], isIn(['Person', 'Company']));
        }
      });

      test('executes query with WITH clause', () async {
        final result = await session.run(
          '''
          MATCH (p:Person)
          WITH p, p.age * 365 AS age_in_days
          WHERE age_in_days > \$minDays
          RETURN p.name AS name, age_in_days
          ORDER BY age_in_days DESC
          LIMIT 5
        ''',
          {'minDays': 7300},
        ); // ~20 years

        final records = await result.list();
        expect(records.length, lessThanOrEqualTo(5));

        for (final record in records) {
          expect(record['name'], isA<String>());
          expect(record['age_in_days'], greaterThan(7300));
        }
      });

      test('executes path query', () async {
        final result = await session.run(
          '''
          MATCH path = (start:Person)-[:KNOWS*1..3]->(end:Person)
          WHERE start.name = \$startName AND end.name <> start.name
          RETURN length(path) AS path_length, end.name AS connected_person
          ORDER BY path_length, connected_person
          LIMIT 10
        ''',
          {'startName': 'Alice'},
        );

        final records = await result.list();

        for (final record in records) {
          expect(record['path_length'], isA<int>());
          expect(record['connected_person'], isA<String>());
          expect(record['path_length'], inInclusiveRange(1, 3));
        }
      });
    });

    group('Parameter Handling', () {
      test('handles string parameters', () async {
        final result = await session.run(
          '''
          MATCH (p:Person {name: \$name})
          RETURN p.name AS name, p.age AS age
        ''',
          {'name': 'Alice'},
        );

        final records = await result.list();
        if (records.isNotEmpty) {
          expect(records.first['name'], equals('Alice'));
        }
      });

      test('handles numeric parameters', () async {
        final result = await session.run(
          '''
          MATCH (p:Person)
          WHERE p.age = \$age
          RETURN p.name AS name, p.age AS age
        ''',
          {'age': 30},
        );

        final records = await result.list();
        for (final record in records) {
          expect(record['age'], equals(30));
        }
      });

      test('handles boolean parameters', () async {
        // Clean up first to ensure isolation
        await session.run('MATCH (p:Person {name: "Test"}) DETACH DELETE p');
        await session.run('CREATE (p:Person {name: "Test", active: true})');

        final result = await session.run(
          '''
          MATCH (p:Person {name: "Test"})
          WHERE p.active = \$isActive
          RETURN p.name AS name, p.active AS active
        ''',
          {'isActive': true},
        );

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['active'], isTrue);

        // Clean up after test
        await session.run('MATCH (p:Person {name: "Test"}) DETACH DELETE p');
      });

      test('handles list parameters', () async {
        final result = await session.run(
          '''
          MATCH (p:Person)
          WHERE p.name IN \$names
          RETURN p.name AS name
          ORDER BY p.name
        ''',
          {
            'names': ['Alice', 'Bob', 'Charlie'],
          },
        );

        final records = await result.list();
        for (final record in records) {
          expect(['Alice', 'Bob', 'Charlie'], contains(record['name']));
        }
      });

      test('handles map parameters', () async {
        await session.run(
          '''
          CREATE (p:Person \$personData)
        ''',
          {
            'personData': {
              'name': 'Map Person',
              'age': 35,
              'email': 'map@example.com',
            },
          },
        );

        final result = await session.run('''
          MATCH (p:Person {name: "Map Person"})
          RETURN p.name AS name, p.age AS age, p.email AS email
        ''');

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['name'], equals('Map Person'));
        expect(records.first['age'], equals(35));
        expect(records.first['email'], equals('map@example.com'));
      });

      test('handles null parameters', () async {
        final result = await session.run(
          '''
          RETURN \$nullParam AS null_value, \$stringParam AS string_value
        ''',
          {'nullParam': null, 'stringParam': 'not null'},
        );

        final records = await result.list();
        expect(records, hasLength(1));
        expect(records.first['null_value'], isNull);
        expect(records.first['string_value'], equals('not null'));
      });

      test('handles complex nested parameters', () async {
        final complexData = {
          'person': {
            'name': 'Complex Person',
            'details': {
              'age': 28,
              'skills': ['Dart', 'Flutter', 'Neo4j'],
            },
          },
          'metadata': {
            'created': DateTime.now().millisecondsSinceEpoch,
            'tags': ['test', 'complex'],
          },
        };

        final result = await session.run(
          '''
          RETURN \$data AS data
        ''',
          {'data': complexData},
        );

        final records = await result.list();
        expect(records, hasLength(1));

        final returnedData = records.first['data'] as Map;
        expect(returnedData['person']['name'], equals('Complex Person'));
        expect(returnedData['person']['details']['age'], equals(28));
        expect(returnedData['person']['details']['skills'], isA<List>());
      });
    });

    group('Data Types and Conversions', () {
      test('handles all basic Neo4j data types', () async {
        final result = await session.run('''
          RETURN 
            true AS boolean_true,
            false AS boolean_false,
            42 AS integer,
            3.14159 AS float,
            "Hello, World!" AS string,
            [1, 2, 3, "mixed", true] AS list,
            {name: "John", age: 30, active: true} AS map
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['boolean_true'], isTrue);
        expect(record['boolean_false'], isFalse);
        expect(record['integer'], equals(42));
        expect(record['float'], closeTo(3.14159, 0.00001));
        expect(record['string'], equals('Hello, World!'));

        final list = record['list'] as List;
        expect(list, hasLength(5));
        expect(list[0], equals(1));
        expect(list[3], equals('mixed'));
        expect(list[4], isTrue);

        final map = record['map'] as Map;
        expect(map['name'], equals('John'));
        expect(map['age'], equals(30));
        expect(map['active'], isTrue);
      });

      test('handles temporal types (dates and times)', () async {
        final result = await session.run('''
          RETURN 
            date() AS current_date,
            time() AS current_time,
            datetime() AS current_datetime,
            localdatetime() AS current_localdatetime,
            duration({days: 1, hours: 2, minutes: 30}) AS duration_value
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        // The exact types depend on the dart_bolt implementation
        expect(record['current_date'], isNotNull);
        expect(record['current_time'], isNotNull);
        expect(record['current_datetime'], isNotNull);
        expect(record['current_localdatetime'], isNotNull);
        expect(record['duration_value'], isNotNull);
      });

      test('handles spatial types (points)', () async {
        final result = await session.run('''
          RETURN 
            point({x: 1.0, y: 2.0}) AS cartesian_point,
            point({latitude: 40.7128, longitude: -74.0060}) AS geographic_point
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['cartesian_point'], isNotNull);
        expect(record['geographic_point'], isNotNull);
      });

      test('handles large numbers', () async {
        final result = await session.run('''
          RETURN 
            9223372036854775807 AS max_long,
            -9223372036854775808 AS min_long,
            1.7976931348623157e+308 AS large_double
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['max_long'], isA<int>());
        expect(record['min_long'], isA<int>());
        expect(record['large_double'], isA<double>());
      });

      test('handles Unicode and special characters', () async {
        final result = await session.run('''
          RETURN 
            "Hello, 世界!" AS unicode_string,
            "Emoji: 🚀🌟💫" AS emoji_string,
            "Special: \\"quotes\\" and \\n newlines" AS special_chars
        ''');

        final records = await result.list();
        expect(records, hasLength(1));

        final record = records.first;
        expect(record['unicode_string'], equals('Hello, 世界!'));
        expect(record['emoji_string'], equals('Emoji: 🚀🌟💫'));
        expect(
          record['special_chars'],
          equals('Special: "quotes" and \n newlines'),
        );
      });
    });

    group('Performance and Optimization', () {
      test('executes query with EXPLAIN (planning)', () async {
        final result = await session.run('''
          EXPLAIN MATCH (p:Person)-[:WORKS_FOR]->(c:Company)
          RETURN p.name, c.name
        ''');

        // EXPLAIN queries don't return data records, but the query should execute successfully
        // The execution plan information is typically in the summary or metadata
        final records = await result.list();
        expect(records, isEmpty); // EXPLAIN returns no data records

        // Verify the query executed successfully by checking the summary
        final summary = await result.summary();
        expect(summary.queryType, equals('r')); // Should be a read query
      });

      test('executes query with PROFILE (execution statistics)', () async {
        final result = await session.run('''
          PROFILE MATCH (p:Person)
          WHERE p.age > 25
          RETURN count(p) AS count
        ''');

        // PROFILE queries return both results and execution statistics
        final records = await result.list();
        expect(records, isNotEmpty);
      });

      test('handles queries with index hints', () async {
        // First, let's create an index (this might fail if it already exists)
        try {
          await session.run(
            'CREATE INDEX person_name_index IF NOT EXISTS FOR (p:Person) ON (p.name)',
          );
        } catch (e) {
          // Index might already exist
        }

        final result = await session.run(
          '''
          MATCH (p:Person)
          USING INDEX p:Person(name)
          WHERE p.name = \$name
          RETURN p.name AS name, p.age AS age
        ''',
          {'name': 'Alice'},
        );

        final _ = await result.list();
        // Should work regardless of whether the index exists
      });
    });

    group('Transaction Behavior', () {
      test('auto-commit transaction isolation', () async {
        // Execute multiple auto-commit queries and verify they're isolated
        final results = await Future.wait([
          session.run('RETURN 1 AS value'),
          session.run('RETURN 2 AS value'),
          session.run('RETURN 3 AS value'),
        ]);

        final values = await Future.wait(
          results.map((r) async => (await r.list()).first['value']),
        );

        expect(values, containsAll([1, 2, 3]));
      });

      test('explicit transaction with multiple queries', () async {
        final transaction = await session.beginTransaction();

        try {
          await transaction.run('CREATE (p:TempPerson {name: "Tx Person 1"})');
          await transaction.run('CREATE (p:TempPerson {name: "Tx Person 2"})');

          final result = await transaction.run(
            'MATCH (p:TempPerson) RETURN count(p) AS count',
          );
          final records = await result.list();
          expect(records.first['count'], equals(2));

          await transaction.commit();

          // Verify data persists after commit
          final verifyResult = await session.run(
            'MATCH (p:TempPerson) RETURN count(p) AS count',
          );
          final verifyRecords = await verifyResult.list();
          expect(verifyRecords.first['count'], equals(2));
        } finally {
          if (!transaction.isClosed) {
            await transaction.rollback();
          }
        }
      });
    });

    group('Error Scenarios', () {
      test('handles syntax errors gracefully', () async {
        await expectLater(
          session.run('INVALID CYPHER SYNTAX HERE'),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('handles constraint violations', () async {
        // Create a unique constraint
        try {
          await session.run(
            'CREATE CONSTRAINT unique_email IF NOT EXISTS FOR (p:Person) REQUIRE p.email IS UNIQUE',
          );
        } catch (e) {
          // Constraint might already exist
        }

        // Create first person with email
        await session.run(
          'CREATE (p:Person {name: "First", email: "unique@test.com"})',
        );

        // Try to create second person with same email
        await expectLater(
          session.run(
            'CREATE (p:Person {name: "Second", email: "unique@test.com"})',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('handles missing parameters', () async {
        await expectLater(
          session.run('MATCH (p:Person {name: \$missingParam}) RETURN p'),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('handles type mismatches in parameters', () async {
        // This might or might not throw depending on Neo4j's type coercion
        final result = await session.run(
          '''
          RETURN \$number AS number_value
        ''',
          {'number': 'not_a_number'},
        );

        final records = await result.list();
        expect(records.first['number_value'], equals('not_a_number'));
      });
    });
  });
}
