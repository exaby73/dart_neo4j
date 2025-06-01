/// A Dart implementation of the PackStream binary serialization format.
///
/// PackStream is a binary presentation format for the exchange of richly-typed
/// data. It provides a syntax layer for the Bolt messaging protocol used by Neo4j.
///
/// This library provides a complete implementation of PackStream version 1,
/// supporting all core data types:
///
/// ## Core Data Types
///
/// - **Null**: [PsNull] - missing or empty value
/// - **Boolean**: [PsBoolean] - true or false
/// - **Integer**: [PsInt] family - signed 64-bit integers with multiple representations
///   - [PsTinyInt] - 1 byte for values -16 to 127
///   - [PsInt8] - 2 bytes for values -128 to -17
///   - [PsInt16] - 3 bytes for larger 16-bit values
///   - [PsInt32] - 5 bytes for larger 32-bit values
///   - [PsInt64] - 9 bytes for full 64-bit range
/// - **Float**: [PsFloat] - 64-bit floating point numbers
/// - **Bytes**: [PsBytes] - byte arrays
/// - **String**: [PsString] - UTF-8 encoded text
/// - **List**: [PsList] - ordered collection of values
/// - **Dictionary**: [PsDictionary] - collection of key-value entries
/// - **Structure**: [Structure] - composite values with type signatures
///
/// ## Usage
///
/// ### Creating PackStream Values
///
/// ```dart
/// import 'package:dart_packstream/dart_packstream.dart';
///
/// // Create values directly
/// final nullValue = PsNull();
/// final boolValue = PsBoolean(true);
/// final intValue = PsInt.compact(42); // Automatically chooses optimal representation
/// final floatValue = PsFloat(3.14159);
/// final stringValue = PsString("Hello, World!");
/// final bytesValue = PsBytes(Uint8List.fromList([1, 2, 3, 4]));
///
/// // Create collections
/// final listValue = PsList([intValue, stringValue, boolValue]);
/// final dictValue = PsDictionary({
///   PsString("name"): PsString("Alice"),
///   PsString("age"): PsInt.compact(30),
/// });
/// ```
///
/// ### Converting from Dart Values
///
/// ```dart
/// // Automatic conversion from Dart types
/// final psValue = PsDataType.fromValue("Hello"); // Creates PsString
/// final psInt = PsDataType.fromValue(42); // Creates optimal PsInt
/// final psList = PsDataType.fromValue([1, "two", true]); // Creates PsList
/// final psDict = PsDataType.fromValue({"key": "value"}); // Creates PsDictionary
/// ```
///
/// ### Serialization and Deserialization
///
/// ```dart
/// // Serialize to bytes
/// final bytes = stringValue.toBytes(); // Uint8List
/// final byteData = stringValue.toByteData(); // ByteData
///
/// // Deserialize from bytes
/// final parsed = PsDataType.fromPackStreamBytes(ByteData.view(bytes.buffer));
/// print(parsed.dartValue); // "Hello, World!"
/// ```
///
/// ### Working with Structures
///
/// Structures require registration of factory functions:
///
/// ```dart
/// // Register a structure type (typically done by consumer libraries)
/// StructureRegistry.register(0x4E, (values) => MyNodeStructure(values));
///
/// // Create and use structures
/// final structure = MyNodeStructure([PsInt.compact(1), PsString("label")]);
/// final bytes = structure.toBytes();
/// ```
///
/// ## Type Safety
///
/// All PackStream types are strongly typed and provide both the original
/// PackStream representation and convenient Dart value access:
///
/// ```dart
/// final psString = PsString("Hello");
/// print(psString.value); // "Hello" (String)
/// print(psString.dartValue); // "Hello" (String)
/// print(psString.marker); // 0x85 (int - the PackStream marker byte)
/// ```
library;

// Export the main data type base class
export 'src/ps_data_type.dart' show PsDataType;

// Export all core data types
export 'src/ps_data_type.dart' show PsNull;
export 'src/ps_data_type.dart' show PsBoolean;
export 'src/ps_data_type.dart' show PsInt;
export 'src/ps_data_type.dart' show PsTinyInt;
export 'src/ps_data_type.dart' show PsInt8;
export 'src/ps_data_type.dart' show PsInt16;
export 'src/ps_data_type.dart' show PsInt32;
export 'src/ps_data_type.dart' show PsInt64;
export 'src/ps_data_type.dart' show PsFloat;
export 'src/ps_data_type.dart' show PsString;
export 'src/ps_data_type.dart' show PsBytes;
export 'src/ps_data_type.dart' show PsList;
export 'src/ps_data_type.dart' show PsDictionary;

// Export structure-related classes
export 'src/ps_data_type.dart' show Structure;
export 'src/ps_data_type.dart' show StructureRegistry;
export 'src/ps_data_type.dart' show StructureFactory;
