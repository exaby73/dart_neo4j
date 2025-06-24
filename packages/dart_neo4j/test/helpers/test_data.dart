import 'package:dart_neo4j/dart_neo4j.dart';

/// Helper class for creating test data in Neo4j
class TestData {
  /// Creates sample nodes and relationships for testing
  static Future<void> createSampleData(Session session) async {
    // Clear existing data first
    await session.run('MATCH (n) DETACH DELETE n');

    // Create sample nodes
    await session.run('''
      CREATE (alice:Person {name: 'Alice', age: 30, city: 'New York'})
      CREATE (bob:Person {name: 'Bob', age: 25, city: 'San Francisco'})
      CREATE (charlie:Person {name: 'Charlie', age: 35, city: 'London'})
      CREATE (company:Company {name: 'TechCorp', founded: 2010})
      CREATE (project:Project {name: 'Project Alpha', status: 'active'})
    ''');

    // Create sample relationships
    await session.run('''
      MATCH (alice:Person {name: 'Alice'})
      MATCH (bob:Person {name: 'Bob'})
      MATCH (charlie:Person {name: 'Charlie'})
      MATCH (company:Company {name: 'TechCorp'})
      MATCH (project:Project {name: 'Project Alpha'})
      
      CREATE (alice)-[:KNOWS {since: 2020}]->(bob)
      CREATE (bob)-[:KNOWS {since: 2021}]->(charlie)
      CREATE (alice)-[:WORKS_FOR {role: 'Engineer', since: 2019}]->(company)
      CREATE (bob)-[:WORKS_FOR {role: 'Designer', since: 2020}]->(company)
      CREATE (alice)-[:WORKS_ON {responsibility: 'Lead'}]->(project)
      CREATE (bob)-[:WORKS_ON {responsibility: 'UI/UX'}]->(project)
    ''');
  }

  /// Creates a large dataset for performance testing
  static Future<void> createLargeDataset(
    Session session, {
    int nodeCount = 1000,
    int relationshipCount = 500,
  }) async {
    // Clear existing data
    await session.run('MATCH (n) DETACH DELETE n');

    // Create nodes in batches
    const batchSize = 100;
    for (int i = 0; i < nodeCount; i += batchSize) {
      final endIndex = (i + batchSize < nodeCount) ? i + batchSize : nodeCount;
      final batch = StringBuffer();

      for (int j = i; j < endIndex; j++) {
        if (j > i) batch.write('\n');
        batch.write(
          'CREATE (:TestNode {id: $j, value: ${j * 10}, category: "${j % 5}"})',
        );
      }

      await session.run(batch.toString());
    }

    // Create relationships in batches using separate queries
    const relBatchSize = 50;
    for (int i = 0; i < relationshipCount; i += relBatchSize) {
      final endIndex =
          (i + relBatchSize < relationshipCount)
              ? i + relBatchSize
              : relationshipCount;

      for (int j = i; j < endIndex; j++) {
        final from = j % nodeCount;
        final to = (j + 1) % nodeCount;

        // Use separate queries to avoid CREATE/MATCH mixing issues
        await session.run(
          '''
          MATCH (a:TestNode {id: \$from}), (b:TestNode {id: \$to})
          CREATE (a)-[:TEST_RELATION {weight: rand()}]->(b)
        ''',
          {'from': from, 'to': to},
        );
      }
    }
  }

  /// Creates data with various types for type testing
  static Future<void> createTypeTestData(Session session) async {
    await session.run('MATCH (n) DETACH DELETE n');

    await session.run('''
      CREATE (test:TypeTest {
        stringValue: 'Hello World',
        intValue: 42,
        floatValue: 3.14159,
        boolValue: true,
        nullValue: null,
        listValue: [1, 2, 3, 'four', true],
        mapValue: {key1: 'value1', key2: 42, nested: {inner: 'data'}},
        dateValue: datetime('2023-01-01T12:00:00Z'),
        durationValue: duration({days: 1, hours: 2, minutes: 30})
      })
    ''');
  }

  /// Creates path test data
  static Future<void> createPathTestData(Session session) async {
    await session.run('MATCH (n) DETACH DELETE n');

    await session.run('''
      CREATE (a:Node {name: 'A'})
      CREATE (b:Node {name: 'B'})
      CREATE (c:Node {name: 'C'})
      CREATE (d:Node {name: 'D'})
      CREATE (e:Node {name: 'E'})
      
      CREATE (a)-[:STEP {order: 1}]->(b)
      CREATE (b)-[:STEP {order: 2}]->(c)
      CREATE (c)-[:STEP {order: 3}]->(d)
      CREATE (d)-[:STEP {order: 4}]->(e)
      CREATE (a)-[:DIRECT]->(e)
    ''');
  }

  /// Cleans up all test data
  static Future<void> cleanup(Session session) async {
    await session.run('MATCH (n) DETACH DELETE n');
  }

  /// Gets count of all nodes
  static Future<int> getNodeCount(Session session) async {
    final result = await session.run('MATCH (n) RETURN count(n) as count');
    final record = await result.single();
    return record.getInt('count');
  }

  /// Gets count of all relationships
  static Future<int> getRelationshipCount(Session session) async {
    final result = await session.run(
      'MATCH ()-[r]->() RETURN count(r) as count',
    );
    final record = await result.single();
    return record.getInt('count');
  }

  /// Verifies the database is empty
  static Future<bool> isEmpty(Session session) async {
    final nodeCount = await getNodeCount(session);
    final relCount = await getRelationshipCount(session);
    return nodeCount == 0 && relCount == 0;
  }
}
