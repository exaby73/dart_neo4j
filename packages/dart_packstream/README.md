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

# dart_packstream

A Dart implementation of the PackStream binary serialization format used by Neo4j's Bolt protocol.

[![pub package](https://img.shields.io/pub/v/dart_packstream.svg)](https://pub.dev/packages/dart_packstream)

## Overview

PackStream is a binary presentation format for the exchange of richly-typed data. It provides a syntax layer for the Bolt messaging protocol used by Neo4j. This library provides a complete implementation of PackStream version 1, supporting all core data types with strong type safety and efficient serialization.

## Features

- ✅ Complete PackStream v1 implementation
- ✅ All core data types (Null, Boolean, Integer, Float, Bytes, String, List, Dictionary, Structure)
- ✅ Optimized integer representations (TINY_INT, INT_8, INT_16, INT_32, INT_64)
- ✅ Type-safe serialization and deserialization
- ✅ Automatic conversion from Dart types
- ✅ Structure extension mechanism
- ✅ Big-endian byte ordering compliance
- ✅ UTF-8 string encoding
- ✅ Zero-copy ByteData operations

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dart_packstream: <latest_version>
```

Then run:

```bash
dart pub get
```

## Core Data Types

| PackStream Type | Dart Class     | Description                                           |
| --------------- | -------------- | ----------------------------------------------------- |
| Null            | `PsNull`       | Missing or empty value                                |
| Boolean         | `PsBoolean`    | true or false                                         |
| Integer         | `PsInt` family | Signed 64-bit integers with optimized representations |
| Float           | `PsFloat`      | 64-bit floating point numbers                         |
| Bytes           | `PsBytes`      | Byte arrays                                           |
| String          | `PsString`     | UTF-8 encoded text                                    |
| List            | `PsList`       | Ordered collection of values                          |
| Dictionary      | `PsDictionary` | Collection of key-value entries                       |
| Structure       | `PsStructure`  | Composite values with type signatures                 |

### Integer Representations

The library automatically chooses the most compact integer representation:

- `PsTinyInt` - 1 byte for values -16 to 127
- `PsInt8` - 2 bytes for values -128 to -17
- `PsInt16` - 3 bytes for larger 16-bit values
- `PsInt32` - 5 bytes for larger 32-bit values
- `PsInt64` - 9 bytes for full 64-bit range

## Usage

### Creating PackStream Values

```dart
import 'package:dart_packstream/dart_packstream.dart';

// Basic types
final nullValue = PsNull();
final boolValue = PsBoolean(true);
final intValue = PsInt.compact(42); // Automatically chooses optimal representation
final floatValue = PsFloat(3.14159);
final stringValue = PsString("Hello, World!");
final bytesValue = PsBytes(Uint8List.fromList([1, 2, 3, 4]));

// Collections
final listValue = PsList([intValue, stringValue, boolValue]);
final dictValue = PsDictionary({
  PsString("name"): PsString("Alice"),
  PsString("age"): PsInt.compact(30),
});
```

### Automatic Conversion from Dart Types

```dart
// Convert Dart values automatically
final psString = PsDataType.fromValue("Hello"); // -> PsString
final psInt = PsDataType.fromValue(42); // -> optimal PsInt representation
final psList = PsDataType.fromValue([1, "two", true]); // -> PsList
final psDict = PsDataType.fromValue({"key": "value"}); // -> PsDictionary
final psBytes = PsDataType.fromValue(Uint8List.fromList([1, 2, 3])); // -> PsBytes
```

### Serialization and Deserialization

```dart
// Serialize to bytes
final value = PsString("Hello, World!");
final bytes = value.toBytes(); // Uint8List
final byteData = value.toByteData(); // ByteData

// Deserialize from bytes
final parsed = PsDataType.fromPackStreamBytes(ByteData.view(bytes.buffer));
print(parsed.dartValue); // "Hello, World!"

// Access both PackStream and Dart representations
print(value.value); // "Hello, World!" (original)
print(value.dartValue); // "Hello, World!" (converted)
print(value.marker); // 0x85 (PackStream marker byte)
```

### Working with Collections

```dart
// Lists can contain mixed types
final mixedList = PsList([
  PsInt.compact(1),
  PsString("two"),
  PsBoolean(true),
  PsFloat(4.0),
]);

// Dictionaries use PsString keys
final person = PsDictionary({
  PsString("id"): PsInt.compact(12345),
  PsString("name"): PsString("John Doe"),
  PsString("active"): PsBoolean(true),
  PsString("score"): PsFloat(98.5),
});

// Access values by converting to Dart types
final Map<String, dynamic> dartMap = person.dartValue;
print(dartMap["name"]); // "John Doe"
```

### Working with Structures

Structures are used for domain-specific data types and require registration:

```dart
// Register a structure factory (typically done by consumer libraries)
PsStructureRegistry.register(0x4E, (values) => MyNodeStructure(values));

// Create structures
class MyNodeStructure extends PsStructure {
  MyNodeStructure(List<PsDataType> values) : super(0x4E, values);

  int get id => values[0].dartValue;
  String get label => values[1].dartValue;
}

// Use structures
final structure = MyNodeStructure([
  PsInt.compact(1),
  PsString("Person")
]);

final bytes = structure.toBytes();
final parsed = PsDataType.fromPackStreamBytes(ByteData.view(bytes.buffer));
```

### Type Safety and Conversion

All PackStream types provide strong typing and convenient access patterns:

```dart
final psValue = PsString("Hello");

// Type-safe access
String stringValue = psValue.value; // Direct access to wrapped value
dynamic dartValue = psValue.dartValue; // Dart-compatible representation
int marker = psValue.marker; // PackStream marker byte

// Pattern matching
switch (psValue.runtimeType) {
  case PsString:
    print("It's a string: ${psValue.value}");
    break;
  case PsInt:
    print("It's an integer: ${psValue.value}");
    break;
  // ... other types
}
```

## Performance Considerations

- Use `PsInt.compact()` for automatic optimal integer representation
- Prefer `ByteData` operations for high-performance scenarios
- Structure factories are cached for efficient deserialization
- The library uses zero-copy operations where possible

## PackStream Specification Compliance

This library implements PackStream v1 according to the [official specification](https://neo4j.com/docs/bolt/current/packstream/):

- Big-endian byte ordering
- UTF-8 string encoding
- IEEE 754 double-precision floats
- Optimal integer representations
- Variable-length encoding for collections
- Structure extension mechanism

## Related Packages

This library is part of the `dart_neo4j` ecosystem:

- [`dart_bolt`](../dart_bolt) - Neo4j Bolt protocol implementation
- [`dart_neo4j`](../dart_neo4j) - Complete Neo4j driver

## Contributing

Contributions are welcome! Please read the contributing guidelines and submit pull requests to the [GitHub repository](https://github.com/exaby73/dart_neo4j).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
