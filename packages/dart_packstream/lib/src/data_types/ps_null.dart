part of '../ps_data_type.dart';

/// Represents a null value in the PackStream format.
///
/// Null is always encoded using the single marker byte `0xC0`. This represents
/// a missing or empty value in the PackStream binary format.
///
/// Example:
/// ```dart
/// final nullValue = PsNull();
/// print(nullValue.value); // null
/// print(nullValue.toBytes()); // [0xC0]
/// ```
final class PsNull extends PsDataType<Null, Null> {
  /// Creates a new PackStream null value.
  const PsNull();

  /// Returns null as this represents a null value.
  @override
  Null get value => null;

  /// Returns the marker byte for null values (0xC0).
  @override
  int get marker => 0xC0;

  /// Returns null as this represents a null value.
  @override
  Null get dartValue => null;

  /// Creates a [PsNull] from PackStream bytes.
  ///
  /// The bytes must contain exactly one byte with the value `0xC0`.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes contain more or less than 1 byte
  /// - The single byte is not `0xC0`
  PsNull.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes != 1) {
      throw ArgumentError(
        'Invalid number of bytes for Null: ${bytes.lengthInBytes}',
      );
    }

    if (bytes.getUint8(0) != marker) {
      throw ArgumentError('Invalid marker for Null: ${bytes.getUint8(0)}');
    }
  }

  /// Converts this null value to its PackStream byte representation.
  ///
  /// Returns a single byte with the value `0xC0`.
  @override
  ByteData toByteData() {
    return ByteData(1)..setUint8(0, marker);
  }

  /// Checks if this null value equals another object.
  ///
  /// Returns true if the other object is also a [PsNull].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PsNull;
  }

  /// Returns the hash code for this null value.
  @override
  int get hashCode => null.hashCode;

  /// Returns a string representation of this null value.
  @override
  String toString() => 'PsNull()';
}
