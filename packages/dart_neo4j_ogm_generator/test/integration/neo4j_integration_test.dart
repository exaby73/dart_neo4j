import 'dart:io';

import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
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
        id: CypherId.value(123),
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
        equals('CREATE (u:User {name: \$name, email: \$email}) RETURN u'),
      );
      expect(params, equals({'name': 'John Doe', 'email': 'john@example.com'}));

      // Execute the query with Neo4j (manually add id as property for testing)
      final paramsWithId = Map<String, dynamic>.from(params);
      paramsWithId['id'] = user.id.idOrThrow;
      final createQueryWithId =
          'CREATE (u:User {id: \$id, name: \$name, email: \$email}) RETURN u';
      final result = await session.run(createQueryWithId, paramsWithId);
      final records = await result.list();

      expect(records, hasLength(1));
      final createdNode = records.first.getNode('u');
      expect(createdNode.properties['id'], equals(123));
      expect(createdNode.properties['name'], equals('John Doe'));
      expect(createdNode.properties['email'], equals('john@example.com'));
      expect(createdNode.labels, contains('User'));
    });

    test(
      'Customer class with custom label - CREATE node with generated methods',
      () async {
        final customer = Customer(id: CypherId.value(456), name: 'Jane Smith');

        // Test the generated methods with custom label
        final createQuery =
            'CREATE ${customer.toCypherWithPlaceholders('c')} RETURN c';
        final params = customer.cypherParameters;

        // Verify the generated Cypher uses the custom label 'Person'
        expect(
          createQuery,
          equals('CREATE (c:Person {name: \$name}) RETURN c'),
        );
        expect(params, equals({'name': 'Jane Smith'}));

        // Execute the query with Neo4j (manually add id as property for testing)
        final paramsWithId = Map<String, dynamic>.from(params);
        paramsWithId['id'] = customer.id.idOrThrow;
        final createQueryWithId =
            'CREATE (c:Person {id: \$id, name: \$name}) RETURN c';
        final result = await session.run(createQueryWithId, paramsWithId);
        final records = await result.list();

        expect(records, hasLength(1));
        final createdNode = records.first.getNode('c');
        expect(createdNode.properties['id'], equals(456));
        expect(createdNode.properties['name'], equals('Jane Smith'));
        expect(createdNode.labels, contains('Person'));
      },
    );

    test('MATCH query with generated methods', () async {
      // First create a user
      final user = User(
        id: CypherId.value(789),
        name: 'Test User',
        email: 'test@example.com',
      );

      // Create with id as property for testing
      final createParams = Map<String, dynamic>.from(user.cypherParameters);
      createParams['id'] = user.id.idOrThrow;
      await session.run(
        'CREATE (u:User {id: \$id, name: \$name, email: \$email})',
        createParams,
      );

      // Now test matching with generated methods (match by name and email since id is not in cypher properties)
      final matchQuery = 'MATCH ${user.toCypherWithPlaceholders('u')} RETURN u';
      final result = await session.run(matchQuery, user.cypherParameters);
      final records = await result.list();

      expect(records, hasLength(1));
      final matchedNode = records.first.getNode('u');
      expect(matchedNode.properties['id'], equals(789));
      expect(matchedNode.properties['name'], equals('Test User'));
      expect(matchedNode.properties['email'], equals('test@example.com'));
    });

    test('Prefixed parameters to avoid name collisions', () async {
      final user1 = User(
        id: CypherId.value(1),
        name: 'User One',
        email: 'user1@example.com',
      );

      final user2 = User(
        id: CypherId.value(2),
        name: 'User Two',
        email: 'user2@example.com',
      );

      // Test prefixed methods to avoid parameter name collisions
      final createQuery = '''
        CREATE (u1:User {id: \$first_id, name: \$first_name, email: \$first_email}), 
               (u2:User {id: \$second_id, name: \$second_name, email: \$second_email})
        RETURN u1, u2
      ''';

      final params = <String, dynamic>{};
      params.addAll(user1.cypherParametersWithPrefix('first_'));
      params.addAll(user2.cypherParametersWithPrefix('second_'));
      // Manually add IDs for testing
      params['first_id'] = user1.id.idOrThrow;
      params['second_id'] = user2.id.idOrThrow;

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

      expect(u1.properties['id'], equals(1));
      expect(u1.properties['name'], equals('User One'));
      expect(u2.properties['id'], equals(2));
      expect(u2.properties['name'], equals('User Two'));
    });

    test('Complex query with relationships', () async {
      final user = User(
        id: CypherId.value(100),
        name: 'Relationship User',
        email: 'rel@example.com',
      );

      final customer = Customer(
        id: CypherId.value(200),
        name: 'Relationship Customer',
      );

      // Create nodes and relationship
      final createQuery = '''
        CREATE (u:User {id: \$user_id, name: \$user_name, email: \$user_email}),
               (c:Person {id: \$cust_id, name: \$cust_name}),
               (u)-[:KNOWS]->(c)
        RETURN u, c
      ''';

      final params = <String, dynamic>{};
      params.addAll(user.cypherParametersWithPrefix('user_'));
      params.addAll(customer.cypherParametersWithPrefix('cust_'));
      // Manually add IDs for testing
      params['user_id'] = user.id.idOrThrow;
      params['cust_id'] = customer.id.idOrThrow;

      final result = await session.run(createQuery, params);
      final records = await result.list();

      expect(records, hasLength(1));
      final u = records.first.getNode('u');
      final c = records.first.getNode('c');

      expect(u.properties['id'], equals(100));
      expect(c.properties['id'], equals(200));
      expect(u.labels, contains('User'));
      expect(c.labels, contains('Person'));
    });

    test('fromNode factory constructor', () async {
      // Create a user in the database
      final originalUser = User(
        id: CypherId.value(999),
        name: 'Factory User',
        email: 'factory@example.com',
      );

      // Create with id as property for testing
      final createParams = Map<String, dynamic>.from(
        originalUser.cypherParameters,
      );
      createParams['id'] = originalUser.id.idOrThrow;
      await session.run(
        'CREATE (u:User {id: \$id, name: \$name, email: \$email})',
        createParams,
      );

      // Query and reconstruct using factory
      final result = await session.run('MATCH (u:User {id: \$id}) RETURN u', {
        'id': 999,
      });
      final records = await result.list();

      expect(records, hasLength(1));
      final node = records.first.getNode('u');

      // Use the generated factory constructor
      final reconstructedUser = User.fromNode(node);

      expect(
        reconstructedUser.id.idOrThrow,
        equals(node.id),
      ); // Use the actual Neo4j generated ID
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
