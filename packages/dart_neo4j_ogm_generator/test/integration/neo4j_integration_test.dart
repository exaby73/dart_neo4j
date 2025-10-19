import 'dart:io';

import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:test/test.dart';

import '../fixtures/user.dart';
import '../fixtures/person.dart';

void main() {
  group('Neo4j Integration Tests', () {
    late Neo4jDriver driver;
    late Session session;

    setUpAll(() async {
      // Connect to Neo4j using credentials from docker-compose.yml
      // Using the single Neo4j instance on port 7687
      driver = Neo4jDriver.create(
        'bolt://localhost:7687',
        auth: BasicAuth('neo4j', 'password'),
      );

      // Test connection
      try {
        session = driver.session();
        await session.run('RETURN 1 as test');
        await session.close();
      } catch (e) {
        print(
          'Warning: Neo4j connection failed. Make sure Docker containers are running.',
        );
        print('Run: docker-compose up -d');
        rethrow;
      }
    });

    tearDownAll(() async {
      await driver.close();
    });

    setUp(() async {
      session = driver.session();
      // Clean up any existing test data
      await session.run('MATCH (n) DETACH DELETE n');
    });

    tearDown(() async {
      await session.close();
    });

    test('User class - CREATE node with generated methods', () async {
      final user = User(
        id: 'test-123',
        name: 'John Doe',
        email: 'john@example.com',
      );

      // Test the generated toCypherWithPlaceholders method
      final createQuery =
          'CREATE ${user.toCypherWithPlaceholders('u')} RETURN u';
      final params = user.cypherParameters;

      // Verify the generated Cypher syntax
      expect(
        createQuery,
        equals(
          'CREATE (u:User {id: \$id, name: \$name, email: \$email}) RETURN u',
        ),
      );
      expect(
        params,
        equals({
          'id': 'test-123',
          'name': 'John Doe',
          'email': 'john@example.com',
        }),
      );

      // Execute the query with Neo4j
      final result = await session.run(createQuery, params);
      final records = await result.list();

      expect(records, hasLength(1));
      final createdNode = records.first.getNode('u');
      expect(createdNode.properties['id'], equals('test-123'));
      expect(createdNode.properties['name'], equals('John Doe'));
      expect(createdNode.properties['email'], equals('john@example.com'));
      expect(createdNode.labels, contains('User'));
    });

    test(
      'Customer class with custom label - CREATE node with generated methods',
      () async {
        final customer = Customer(id: 'cust-456', name: 'Jane Smith');

        // Test the generated methods with custom label
        final createQuery =
            'CREATE ${customer.toCypherWithPlaceholders('c')} RETURN c';
        final params = customer.cypherParameters;

        // Verify the generated Cypher uses the custom label 'Person'
        expect(
          createQuery,
          equals('CREATE (c:Person {id: \$id, name: \$name}) RETURN c'),
        );
        expect(params, equals({'id': 'cust-456', 'name': 'Jane Smith'}));

        // Execute the query with Neo4j
        final result = await session.run(createQuery, params);
        final records = await result.list();

        expect(records, hasLength(1));
        final createdNode = records.first.getNode('c');
        expect(createdNode.properties['id'], equals('cust-456'));
        expect(createdNode.properties['name'], equals('Jane Smith'));
        expect(createdNode.labels, contains('Person'));
      },
    );

    test('MATCH query with generated methods', () async {
      // First create a user
      final user = User(
        id: 'match-test',
        name: 'Test User',
        email: 'test@example.com',
      );

      await session.run(
        'CREATE ${user.toCypherWithPlaceholders('u')}',
        user.cypherParameters,
      );

      // Now test matching with generated methods
      final matchQuery = 'MATCH ${user.toCypherWithPlaceholders('u')} RETURN u';
      final result = await session.run(matchQuery, user.cypherParameters);
      final records = await result.list();

      expect(records, hasLength(1));
      final matchedNode = records.first.getNode('u');
      expect(matchedNode.properties['id'], equals('match-test'));
      expect(matchedNode.properties['name'], equals('Test User'));
      expect(matchedNode.properties['email'], equals('test@example.com'));
    });

    test('Prefixed parameters to avoid name collisions', () async {
      final user1 = User(
        id: 'user1',
        name: 'User One',
        email: 'user1@example.com',
      );

      final user2 = User(
        id: 'user2',
        name: 'User Two',
        email: 'user2@example.com',
      );

      // Test prefixed methods to avoid parameter name collisions
      final createQuery = '''
        CREATE ${user1.toCypherWithPlaceholdersWithPrefix('u1', 'first_')}, 
               ${user2.toCypherWithPlaceholdersWithPrefix('u2', 'second_')}
        RETURN u1, u2
      ''';

      final params = <String, dynamic>{};
      params.addAll(user1.cypherParametersWithPrefix('first_'));
      params.addAll(user2.cypherParametersWithPrefix('second_'));

      // Verify no parameter name collisions
      expect(
        params.keys,
        containsAll([
          'first_id',
          'first_name',
          'first_email',
          'second_id',
          'second_name',
          'second_email',
        ]),
      );

      // Execute the query
      final result = await session.run(createQuery, params);
      final records = await result.list();

      expect(records, hasLength(1));
      final u1 = records.first.getNode('u1');
      final u2 = records.first.getNode('u2');

      expect(u1.properties['id'], equals('user1'));
      expect(u1.properties['name'], equals('User One'));
      expect(u2.properties['id'], equals('user2'));
      expect(u2.properties['name'], equals('User Two'));
    });

    test('Complex query with relationships', () async {
      final user = User(
        id: 'rel-user',
        name: 'Relationship User',
        email: 'rel@example.com',
      );

      final customer = Customer(
        id: 'rel-customer',
        name: 'Relationship Customer',
      );

      // Create nodes and relationship
      final createQuery = '''
        CREATE ${user.toCypherWithPlaceholdersWithPrefix('u', 'user_')},
               ${customer.toCypherWithPlaceholdersWithPrefix('c', 'cust_')},
               (u)-[:KNOWS]->(c)
        RETURN u, c
      ''';

      final params = <String, dynamic>{};
      params.addAll(user.cypherParametersWithPrefix('user_'));
      params.addAll(customer.cypherParametersWithPrefix('cust_'));

      final result = await session.run(createQuery, params);
      final records = await result.list();

      expect(records, hasLength(1));
      final u = records.first.getNode('u');
      final c = records.first.getNode('c');

      expect(u.properties['id'], equals('rel-user'));
      expect(c.properties['id'], equals('rel-customer'));
      expect(u.labels, contains('User'));
      expect(c.labels, contains('Person'));
    });

    test('fromCypherMap factory constructor', () async {
      // Create a user in the database
      final originalUser = User(
        id: 'factory-test',
        name: 'Factory User',
        email: 'factory@example.com',
      );

      await session.run(
        'CREATE ${originalUser.toCypherWithPlaceholders('u')}',
        originalUser.cypherParameters,
      );

      // Query and reconstruct using factory
      final result = await session.run('MATCH (u:User {id: \$id}) RETURN u', {
        'id': 'factory-test',
      });
      final records = await result.list();

      expect(records, hasLength(1));
      final nodeProperties = records.first.getNode('u').properties;

      // Use the generated factory constructor
      final reconstructedUser = User.fromCypherMap(nodeProperties);

      expect(reconstructedUser.id, equals(originalUser.id));
      expect(reconstructedUser.name, equals(originalUser.name));
      expect(reconstructedUser.email, equals(originalUser.email));
    });
  }, skip: _shouldSkipIntegrationTests());
}

/// Skip integration tests if Neo4j is not available
bool _shouldSkipIntegrationTests() {
  final skipTests = Platform.environment['SKIP_NEO4J_TESTS'] == 'true';
  if (skipTests) {
    print('Skipping Neo4j integration tests (SKIP_NEO4J_TESTS=true)');
  }
  return skipTests;
}
