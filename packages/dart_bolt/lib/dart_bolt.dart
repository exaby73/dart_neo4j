/// A Dart implementation of the Bolt protocol for Neo4j.
///
/// This library provides data structures and utilities for working with
/// the Bolt protocol, which is used for communication with Neo4j databases.
///
/// ## Bolt Structures
///
/// This library implements all the standard Bolt structures defined in the
/// Bolt specification:
///
/// ### Graph Structures
/// - [BoltNode] - nodes in a graph database
/// - [BoltRelationship] - relationships between nodes
/// - [BoltUnboundRelationship] - relationships without start/end node IDs
/// - [BoltPath] - sequences of nodes and relationships
///
/// ### Temporal Structures
/// - [BoltDate] - dates without time zones
/// - [BoltTime] - time of day with timezone offset
/// - [BoltLocalTime] - time of day without timezone
/// - [BoltDateTime] - instant with timezone offset
/// - [BoltDateTimeZoneId] - instant with timezone identifier
/// - [BoltLocalDateTime] - instant without timezone
/// - [BoltDuration] - temporal amounts
///
/// ### Spatial Structures
/// - [BoltPoint2D] - 2D points with spatial reference
/// - [BoltPoint3D] - 3D points with spatial reference
///
/// ### Legacy Structures
/// - [BoltLegacyDateTime] - legacy datetime with timezone offset
/// - [BoltLegacyDateTimeZoneId] - legacy datetime with timezone identifier
///
/// ## Bolt Messages
///
/// This library also implements the Bolt messaging protocol:
///
/// ### Request Messages (Client → Server)
/// - [BoltHelloMessage] - initializes connection and authentication
/// - [BoltRunMessage] - executes a Cypher query
/// - [BoltPullMessage] - fetches records from result stream
/// - [BoltDiscardMessage] - discards records from result stream
/// - [BoltBeginMessage] - begins an explicit transaction
/// - [BoltCommitMessage] - commits an explicit transaction
/// - [BoltRollbackMessage] - rolls back an explicit transaction
/// - [BoltResetMessage] - resets connection to initial state
/// - [BoltGoodbyeMessage] - closes connection gracefully
///
/// ### Response Messages (Server → Client)
/// - [BoltSuccessMessage] - indicates successful operation
/// - [BoltFailureMessage] - indicates failed operation
/// - [BoltIgnoredMessage] - indicates ignored operation
/// - [BoltRecordMessage] - carries result data
///
/// ## Usage
///
/// Before using any Bolt structures or messages, you must register them with the
/// PackStream structure registry:
///
/// ```dart
/// import 'package:dart_bolt/dart_bolt.dart';
///
/// void main() {
///   // Register all Bolt structures and messages with a single call
///   registerBolt();
///
///   // Create a HELLO message for authentication
///   final hello = BoltMessageFactory.hello(
///     userAgent: 'MyApp/1.0.0',
///     username: 'neo4j',
///     password: 'password',
///   );
///
///   // Get bytes to send over socket
///   final bytes = hello.toByteData();
///
///   // Create a RUN message to execute a query
///   final run = BoltMessageFactory.run(
///     'MATCH (n:Person) RETURN n.name',
///     parameters: {'limit': 10},
///   );
///
///   // Serialize and deserialize
///   final runBytes = run.toByteData();
///   final parsed = PsDataType.fromPackStreamBytes(runBytes) as BoltRunMessage;
/// }
/// ```
///
/// ## Alternative Registration
///
/// If you only need structures or messages, you can register them separately:
///
/// ```dart
/// // Register only structures
/// registerBoltStructures();
///
/// // Register only messages
/// registerBoltMessages();
/// ```
library;

export 'package:dart_packstream/dart_packstream.dart';

// Graph structures
export 'src/structures/node.dart';
export 'src/structures/relationship.dart';
export 'src/structures/unbound_relationship.dart';
export 'src/structures/path.dart';

// Temporal structures
export 'src/structures/date.dart';
export 'src/structures/time.dart';
export 'src/structures/local_time.dart';
export 'src/structures/date_time.dart';
export 'src/structures/date_time_zone_id.dart';
export 'src/structures/local_date_time.dart';
export 'src/structures/duration.dart';

// Spatial structures
export 'src/structures/point_2d.dart';
export 'src/structures/point_3d.dart';

// Legacy structures
export 'src/structures/legacy_date_time.dart';
export 'src/structures/legacy_date_time_zone_id.dart';

// Bolt messages
export 'src/messages/bolt_message.dart';
export 'src/messages/request_messages.dart';
export 'src/messages/response_messages.dart';
export 'src/messages/message_factory.dart';

// Unified registry
export 'src/registry.dart';

// Connection and networking
export 'src/connection/bolt_socket.dart';
export 'src/connection/bolt_protocol.dart';
export 'src/connection/connection_state.dart';
export 'src/connection/connection_exceptions.dart';
