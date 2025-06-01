import 'dart:collection';
import 'dart:typed_data';
import 'dart:convert';

part 'data_types/ps_boolean.dart';
part 'data_types/ps_bytes.dart';
part 'data_types/ps_dictionary.dart';
part 'data_types/ps_float.dart';
part 'data_types/ps_int.dart';
part 'data_types/ps_int8.dart';
part 'data_types/ps_int16.dart';
part 'data_types/ps_int32.dart';
part 'data_types/ps_int64.dart';
part 'data_types/ps_list.dart';
part 'data_types/ps_null.dart';
part 'data_types/ps_string.dart';
part 'data_types/ps_structure.dart';
part 'data_types/ps_tiny_int.dart';

/// Base class for all PackStream data types.
///
/// PackStream is a binary presentation format for the exchange of richly-typed
/// data. It provides a syntax layer for the Bolt messaging protocol.
///
/// This class serves as the foundation for all specific data types in the
/// PackStream format and provides methods to convert between Dart types and
/// PackStream representations.
sealed class PsDataType<T, D> {
  const PsDataType();

  /// Returns the marker byte for this data type.
  ///
  /// The marker byte contains type information and size information for types
  /// that require it. It is used when serializing the data to bytes.
  int get marker;

  /// Returns the underlying Dart value represented by this PackStream type.
  T get value;

  /// Returns the underlying Dart value represented by this PackStream type.
  D get dartValue;

  /// Creates a PackStream data type from a Dart value.
  ///
  /// This method automatically determines the appropriate PackStream type based
  /// on the provided Dart value:
  /// - `null` → [PsNull]
  /// - `bool` → [PsBoolean]
  /// - `int` → [PsInt] (using the most compact representation)
  /// - `double` → [PsFloat]
  /// - `String` → [PsString]
  /// - `TypedData` (including `Uint8List`, `ByteData`, etc.) → [PsBytes]
  /// - `List<dynamic>` → [PsList] (with recursive conversion of elements)
  /// - `Map<String, dynamic>` → [PsDictionary] (with recursive conversion of values)
  ///
  /// Throws an [ArgumentError] if the value type is not supported.
  factory PsDataType.fromValue(Object? value) {
    return switch (value) {
          null => fromNull(),
          bool b => fromBool(b),
          int i => fromInt(i),
          double d => fromFloat(d),
          String s => fromString(s),
          TypedData data => fromBytes(data),
          List<dynamic> l => fromList(l),
          Map<String, dynamic> m => fromDictionary(m),
          _ => throw ArgumentError('Unsupported type: ${value.runtimeType}'),
        }
        as PsDataType<T, D>;
  }

  /// Creates a [PsNull] value.
  ///
  /// This represents a null or missing value in the PackStream format.
  static PsNull fromNull() => const PsNull();

  /// Creates a [PsBoolean] from a Dart [bool].
  ///
  /// This represents a boolean value (true or false) in the PackStream format.
  static PsBoolean fromBool(bool value) => PsBoolean(value);

  /// Creates a [PsInt] from a Dart [int] using the most compact representation.
  ///
  /// This method automatically selects the most appropriate integer representation
  /// based on the value's magnitude:
  /// - Values between -16 and 127 → TINY_INT (1 byte)
  /// - Values between -128 and -17 → INT_8 (2 bytes)
  /// - Values between -32768 and -129 or 128 to 32767 → INT_16 (3 bytes)
  /// - Values between -2147483648 and -32769 or 32768 to 2147483647 → INT_32 (5 bytes)
  /// - All other values → INT_64 (9 bytes)
  static PsInt fromInt(int value) => PsInt.compact(value);

  /// Creates a [PsFloat] from a Dart [double].
  ///
  /// This represents a double-precision floating-point value in the PackStream format.
  static PsFloat fromFloat(double value) => PsFloat(value);

  /// Creates a [PsString] from a Dart [String].
  ///
  /// This represents a UTF-8 encoded text in the PackStream format.
  static PsString fromString(String value) => PsString(value);

  /// Creates a [PsBytes] from a [Uint8List].
  ///
  /// This represents a byte array in the PackStream format.
  static PsBytes fromUint8List(Uint8List bytes) => PsBytes(bytes);

  /// Creates a [PsBytes] from any [TypedData].
  ///
  /// This converts any TypedData (including Uint8List, ByteData, Int32List, etc.)
  /// to a byte array in the PackStream format.
  static PsBytes fromBytes(TypedData data) =>
      PsBytes(data.buffer.asUint8List());

  /// Creates a [PsList] from a Dart [List], converting each element recursively.
  ///
  /// This represents a heterogeneous sequence of values in the PackStream format.
  /// Each element in the list is converted to its appropriate PackStream type.
  static PsList fromList(List<dynamic> list) =>
      PsList(list.map((e) => PsDataType.fromValue(e)).toList());

  /// Creates a [PsDictionary] from a Dart [Map], converting each value recursively.
  ///
  /// This represents a collection of key-value entries in the PackStream format.
  /// Each key must be a String, and each value is converted to its appropriate PackStream type.
  static PsDictionary fromDictionary(Map<String, dynamic> map) => PsDictionary(
    map.map(
      (key, value) => MapEntry(fromString(key), PsDataType.fromValue(value)),
    ),
  );

  /// Creates a PackStream data type from bytes.
  ///
  /// This method parses binary data according to the PackStream specification and
  /// returns the appropriate PackStream type based on the marker byte.
  ///
  /// Throws an [ArgumentError] if the bytes cannot be parsed or are invalid.
  factory PsDataType.fromPackStreamBytes(ByteData bytes) {
    if (bytes.buffer.lengthInBytes == 0) {
      throw ArgumentError('Bytes must not be empty');
    }

    final firstByte = bytes.getUint8(0);
    return switch (firstByte) {
          0xC0 => const PsNull(),
          0xC1 => PsFloat(bytes.getFloat64(1, Endian.big)),
          0xC2 => PsBoolean(false),
          0xC3 => PsBoolean(true),
          == 0xC8 ||
          == 0xC9 ||
          == 0xCA ||
          == 0xCB => PsInt.compactFromBytes(bytes),
          >= 0x00 && <= 0x7F || >= 0xF0 && <= 0xFF => PsInt.compactFromBytes(
            ByteData(1)..setUint8(0, firstByte),
          ),
          == 0xCC || == 0xCD || == 0xCE => PsBytes.fromPackStreamBytes(bytes),
          >= 0x80 && <= 0x8F ||
          == 0xD0 ||
          == 0xD1 ||
          == 0xD2 => PsString.fromPackStreamBytes(bytes),
          >= 0x90 && <= 0x9F ||
          == 0xD4 ||
          == 0xD5 ||
          == 0xD6 => PsList.fromPackStreamBytes(bytes),
          >= 0xA0 && <= 0xAF ||
          == 0xD8 ||
          == 0xD9 ||
          == 0xDA => PsDictionary.fromPackStreamBytes(bytes),
          >= 0xB0 && <= 0xBF => _parseStructure(firstByte, bytes),
          _ =>
            throw ArgumentError(
              'Invalid PackStream marker byte: 0x${firstByte.toRadixString(16)}',
            ),
        }
        as PsDataType<T, D>;
  }

  /// Parses a Structure from PackStream bytes.
  static PsStructure _parseStructure(int markerByte, ByteData bytes) {
    final numberOfFields = markerByte - 0xB0;

    if (bytes.lengthInBytes < 2) {
      throw ArgumentError(
        'Structure bytes must contain at least marker and tag byte',
      );
    }

    final tagByte = bytes.getUint8(1);
    if (tagByte < 0 || tagByte > 127) {
      throw ArgumentError('Tag byte must be between 0 and 127, got: $tagByte');
    }

    final values = <PsDataType>[];
    int offset = 2; // Skip marker and tag byte

    for (int i = 0; i < numberOfFields; i++) {
      if (offset >= bytes.lengthInBytes) {
        throw ArgumentError('Insufficient bytes for structure fields');
      }

      // Create a view of the remaining bytes
      final fieldBytes = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + offset,
        bytes.lengthInBytes - offset,
      );

      final field = PsDataType.fromPackStreamBytes(fieldBytes);
      values.add(field);

      // Move offset forward by the size of the field
      final fieldSize = field.toByteData().lengthInBytes;
      if (fieldSize <= 0) {
        throw ArgumentError('Invalid field size: $fieldSize');
      }
      offset += fieldSize;
    }

    return PsStructure.createFromParsedValues(tagByte, values);
  }

  /// Converts this PackStream data type to a [ByteData] representation.
  ///
  /// This method serializes the data according to the PackStream specification,
  /// including the marker byte and any additional bytes needed to represent the value.
  ByteData toByteData();

  /// Converts this PackStream data type to a byte array.
  ///
  /// This is a convenience method that calls [toByteData] and converts the result
  /// to a [Uint8List].
  Uint8List toBytes() {
    return toByteData().buffer.asUint8List();
  }
}
