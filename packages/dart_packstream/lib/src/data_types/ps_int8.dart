part of '../ps_data_type.dart';

/// Represents an 8-bit signed integer in the PackStream format.
///
/// INT_8 uses 2 bytes total:
/// - Marker byte: `0xC8`
/// - Value byte: 8-bit signed integer (-128 to 127)
///
/// This representation is automatically chosen by [PsInt.compact] for values
/// in the range -128 to -17 inclusive.
///
/// Example:
/// ```dart
/// final int8 = PsInt8(-100);
/// print(int8.toBytes()); // [0xC8, 0x9C]
/// ```
final class PsInt8 extends PsInt {
  /// Creates a new PackStream 8-bit integer.
  ///
  /// [value] The integer value to represent. Must be in the range -128 to 127.
  PsInt8(this.value);

  /// The 8-bit signed integer value.
  @override
  final int value;

  /// Returns the integer value.
  @override
  int get dartValue => value;

  /// Returns the marker byte for 8-bit integers (0xC8).
  @override
  int get marker => 0xC8;

  /// Creates a [PsInt8] from PackStream bytes.
  ///
  /// The bytes must contain exactly 2 bytes:
  /// - First byte: marker (0xC8)
  /// - Second byte: signed 8-bit integer value
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes don't contain exactly 2 bytes
  /// - The first byte is not the correct marker (0xC8)
  factory PsInt8.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Invalid marker byte: 0xempty');
    }

    if (bytes.lengthInBytes != 2) {
      throw ArgumentError('Not enough bytes for Int8');
    }

    if (bytes.getUint8(0) != 0xC8) {
      throw ArgumentError(
        'Invalid marker byte: 0x${bytes.getUint8(0).toRadixString(16)}',
      );
    }

    return PsInt8(bytes.getInt8(1));
  }

  /// Converts this 8-bit integer to its PackStream byte representation.
  ///
  /// Returns 2 bytes: marker (0xC8) followed by the signed 8-bit value.
  @override
  ByteData toByteData() {
    return ByteData(2)
      ..setUint8(0, marker)
      ..setInt8(1, value);
  }

  /// Checks if this 8-bit integer equals another object.
  ///
  /// Returns true if the other object is a [PsInt8] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsInt8) return false;
    return value == other.value;
  }

  /// Returns the hash code for this 8-bit integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this 8-bit integer.
  @override
  String toString() => 'PsInt8($value)';
}
