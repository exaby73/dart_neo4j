/// A comprehensive Neo4j driver for Dart.
///
/// This library provides a high-level, type-safe interface for connecting to
/// Neo4j databases using the Bolt protocol. It supports both direct connections
/// (bolt://) and routing connections (neo4j://) with full SSL support.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:dart_neo4j/dart_neo4j.dart';
///
/// void main() async {
///   // Create a driver
///   final driver = Neo4jDriver.create(
///     'bolt://localhost:7687',
///     auth: BasicAuth('neo4j', 'password'),
///   );
///
///   // Create a session and run a query
///   final session = driver.session();
///   try {
///     final result = await session.run(
///       'MATCH (p:Person {name: $name}) RETURN p.name, p.age',
///       {'name': 'Alice'}
///     );
///
///     await for (final record in result.records()) {
///       final name = record.getString('p.name');
///       final age = record.getIntOrNull('p.age');
///       print('$name is ${age ?? 'unknown'} years old');
///     }
///   } finally {
///     await session.close();
///   }
///
///   await driver.close();
/// }
/// ```
///
/// ## Type-Safe Result Access
///
/// The driver provides type-safe methods for accessing query results:
///
/// ```dart
/// final record = // ... get record from result
///
/// // Required fields (throw if null or wrong type)
/// final name = record.getString('name');
/// final age = record.getInt('age');
/// final active = record.getBool('active');
///
/// // Optional fields (return null if missing)
/// final email = record.getStringOrNull('email');
/// final score = record.getDoubleOrNull('score');
///
/// // Neo4j types
/// final person = record.getNode('person');
/// final relationship = record.getRelationship('rel');
/// final path = record.getPath('path');
/// ```
///
/// ## Supported URI Schemes
///
/// - **bolt://**: Direct unencrypted connection
/// - **bolt+s://**: Direct encrypted connection with full certificate validation
/// - **bolt+ssc://**: Direct encrypted connection with self-signed certificates
/// - **neo4j://**: Routing unencrypted connection (for clusters)
/// - **neo4j+s://**: Routing encrypted connection with full certificate validation
/// - **neo4j+ssc://**: Routing encrypted connection with self-signed certificates
library;

// Core driver and session
export 'src/driver/neo4j_driver.dart';
export 'src/session/session.dart';
export 'src/session/transaction.dart';

// Connection management (for advanced users)
export 'src/connection/connection_pool.dart';

// Results and types
export 'src/result/result.dart';
export 'src/result/record.dart';
export 'src/result/summary.dart';
export 'src/types/neo4j_types.dart';

// Authentication
export 'src/auth/auth_token.dart';
export 'src/auth/basic_auth.dart';

// Exceptions
export 'src/exceptions/neo4j_exception.dart';
export 'src/exceptions/connection_exception.dart';
export 'src/exceptions/type_exception.dart';

// For advanced users who need direct access to Bolt types,
// import 'package:dart_bolt/dart_bolt.dart' directly.
