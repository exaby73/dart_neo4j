<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Dart Bolt

A Dart implementation of the Bolt protocol for Neo4j databases.

This library provides data structures and utilities for working with the Bolt protocol, which is used for communication with Neo4j databases. It includes both the Bolt structures (nodes, relationships, temporal types, etc.) and the Bolt messaging protocol for client-server communication.

## Features

### Bolt Structures

- **Graph structures**: Nodes, relationships, paths
- **Temporal structures**: Dates, times, durations with timezone support
- **Spatial structures**: 2D and 3D points with spatial reference systems
- **Legacy structures**: Support for older temporal formats

### Bolt Messages

- **Request messages**: HELLO, RUN, PULL, DISCARD, BEGIN, COMMIT, ROLLBACK, RESET, GOODBYE
- **Response messages**: SUCCESS, FAILURE, IGNORED, RECORD
- **Serialization**: Convert messages to ByteData for socket transmission
- **Deserialization**: Parse bytes from Neo4j server responses

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dart_bolt: <latest_version>
```

## Usage

### Basic Setup

Before using any Bolt structures or messages, register them with the PackStream library:

```dart
import 'package:dart_bolt/dart_bolt.dart';

void main() {
  // Register all Bolt structures and messages with a single call
  registerBolt();

  // Now you can use Bolt messages...
}
```

### Creating Bolt Messages

#### Authentication with HELLO

```dart
final hello = BoltMessageFactory.hello(
  userAgent: 'MyApp/1.0.0',
  username: 'neo4j',
  password: 'password',
  boltAgent: {
    'product': 'MyDriver/1.0.0',
    'platform': 'Dart',
  },
);

// Get bytes to send over socket
final bytes = hello.toByteData();
```

#### Executing Queries with RUN

```dart
final run = BoltMessageFactory.run(
  'MATCH (n:Person) WHERE n.age > \$age RETURN n.name',
  parameters: {'age': 25},
  extra: {'mode': 'r', 'db': 'neo4j'},
);

final bytes = run.toByteData();
```

#### Fetching Results with PULL

```dart
// Pull specific number of records
final pull = BoltMessageFactory.pull(n: 100, qid: 1);

// Pull all records (older protocol versions)
final pullAll = BoltMessageFactory.pullAll();

final bytes = pull.toByteData();
```

#### Transaction Management

```dart
// Begin transaction
final begin = BoltMessageFactory.begin(
  bookmarks: ['bookmark1', 'bookmark2'],
  txTimeout: 30000,
  mode: 'w',
  db: 'mydb',
);

// Commit transaction
final commit = BoltMessageFactory.commit();

// Rollback transaction
final rollback = BoltMessageFactory.rollback();
```

### Parsing Server Responses

```dart
// Parse bytes received from Neo4j server
final receivedBytes = ByteData.fromList([...]); // from socket
final message = PsDataType.fromPackStreamBytes(receivedBytes);

if (message is BoltSuccessMessage) {
  print('Success: ${message.metadata?.dartValue}');
} else if (message is BoltFailureMessage) {
  print('Error: ${message.metadata.dartValue}');
} else if (message is BoltRecordMessage) {
  print('Record: ${message.data.dartValue}');
}
```

### Socket Communication Example

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_bolt/dart_bolt.dart';

Future<void> connectToNeo4j() async {
  // Register Bolt messages
  registerBolt();

  // Connect to Neo4j
  final socket = await Socket.connect('localhost', 7687);

  // Bolt handshake
  final handshake = ByteData(20);
  handshake.setUint32(0, 0x6060B017, Endian.big);  // Magic preamble
  handshake.setUint32(4, 0x00000001, Endian.big);   // Version 1
  handshake.setUint32(8, 0x00000000, Endian.big);   // Version 0
  handshake.setUint32(12, 0x00000000, Endian.big);  // Version 0
  handshake.setUint32(16, 0x00000000, Endian.big);  // Version 0

  socket.add(handshake.buffer.asUint8List());

  // Wait for version response
  final versionResponse = await socket.first;
  final agreedVersion = ByteData.view(versionResponse.buffer).getUint32(0, Endian.big);
  print('Agreed version: $agreedVersion');

  // Send HELLO message
  final hello = BoltMessageFactory.hello(
    userAgent: 'dart_bolt/1.0.0',
    username: 'neo4j',
    password: 'password',
  );

  socket.add(hello.toByteData().buffer.asUint8List());

  // Listen for responses
  socket.listen((data) {
    final message = PsDataType.fromPackStreamBytes(ByteData.view(data.buffer));
    print('Received: $message');
  });
}
```

### Working with Bolt Structures

```dart
// Create a node
final node = BoltNode(
  id: 123,
  labels: ['Person', 'Employee'],
  properties: {'name': 'Alice', 'age': 30},
);

// Create a relationship
final rel = BoltRelationship(
  id: 456,
  startNodeId: 123,
  endNodeId: 789,
  type: 'WORKS_FOR',
  properties: {'since': 2020},
);

// Serialize to bytes
final nodeBytes = node.toByteData();
final relBytes = rel.toByteData();
```

## Message Types

### Request Messages (Client → Server)

| Message  | Signature | Description                            |
| -------- | --------- | -------------------------------------- |
| HELLO    | 0x01      | Initialize connection and authenticate |
| RUN      | 0x10      | Execute a Cypher query                 |
| PULL     | 0x3F      | Fetch records from result stream       |
| DISCARD  | 0x2F      | Discard records from result stream     |
| BEGIN    | 0x11      | Begin explicit transaction             |
| COMMIT   | 0x12      | Commit explicit transaction            |
| ROLLBACK | 0x13      | Rollback explicit transaction          |
| RESET    | 0x0F      | Reset connection to initial state      |
| GOODBYE  | 0x02      | Close connection gracefully            |

### Response Messages (Server → Client)

| Message | Signature | Description                    |
| ------- | --------- | ------------------------------ |
| SUCCESS | 0x70      | Indicates successful operation |
| FAILURE | 0x7F      | Indicates failed operation     |
| IGNORED | 0x7E      | Indicates ignored operation    |
| RECORD  | 0x71      | Contains result data           |

## Protocol Versions

This library supports Bolt protocol versions 1.0 through 5.x. The message structure adapts automatically based on the fields provided:

- **Bolt 1.0-3.x**: Basic message structure
- **Bolt 4.0+**: Enhanced with query IDs and streaming support
- **Bolt 5.0+**: Additional authentication and routing features

## Examples

See the `example/` directory for complete working examples:

- `bolt_messages_example.dart` - Comprehensive message creation and serialization
- Socket communication examples (coming soon)

## Testing

Run the test suite:

```bash
dart test
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
