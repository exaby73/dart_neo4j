import 'package:dart_neo4j/dart_neo4j.dart';

void main() async {
  // Create a driver
  final driver = Neo4jDriver.create(
    'bolt://localhost:7687',
    auth: BasicAuth('neo4j', 'password'),
  );

  try {
    // Verify connectivity
    await driver.verifyConnectivity();
    print('Connected to Neo4j!');

    // Create a session
    final session = driver.session();

    try {
      // Run a simple query
      final result = await session.run(
        'RETURN "Hello, Neo4j!" as greeting, 42 as answer',
      );

      // Process results
      await for (final record in result.records()) {
        final greeting = record.getString('greeting');
        final answer = record.getInt('answer');
        print('$greeting The answer is $answer');
      }

      // Get query summary
      final summary = await result.summary();
      print(
        'Query executed in ${summary.resultAvailableAfter?.inMilliseconds ?? 0}ms',
      );
    } finally {
      await session.close();
    }
  } finally {
    await driver.close();
  }
}
