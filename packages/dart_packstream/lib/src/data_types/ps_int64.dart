part of '../ps_data_type.dart';

/// Represents a 64-bit signed integer in the PackStream format.
///
/// INT_64 uses 9 bytes total:
/// - Marker byte: `0xCB`
/// - Value bytes: 64-bit signed integer in big-endian format
///
/// This representation is automatically chosen by [PsInt.compact] for values
/// that don't fit in smaller integer representations, specifically values
/// outside the range -2,147,483,648 to 2,147,483,647.
///
/// This covers the full range of Dart integers on 64-bit platforms:
/// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807.
///
/// Example:
/// ```dart
/// final int64 = PsInt64(9223372036854775807);
/// print(int64.toBytes()); // [0xCB, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
/// ```
final class PsInt64 extends PsInt {
  /// Creates a new PackStream 64-bit integer.
  ///
  /// [value] The integer value to represent. Can be any valid Dart integer.
  PsInt64(this.value);

  /// The 64-bit signed integer value.
  @override
  final int value;

  /// Returns the integer value.
  @override
  int get dartValue => value;

  /// Returns the marker byte for 64-bit integers (0xCB).
  @override
  int get marker => 0xCB;

  /// Creates a [PsInt64] from PackStream bytes.
  ///
  /// The bytes must contain exactly 9 bytes:
  /// - First byte: marker (0xCB)
  /// - Next 8 bytes: signed 64-bit integer value in big-endian format
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes don't contain exactly 9 bytes
  /// - The first byte is not the correct marker (0xCB)
  factory PsInt64.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Invalid marker byte: 0xempty');
    }

    if (bytes.lengthInBytes != 9) {
      throw ArgumentError('Not enough bytes for Int64');
    }

    if (bytes.getUint8(0) != 0xCB) {
      throw ArgumentError(
        'Invalid marker byte: 0x${bytes.getUint8(0).toRadixString(16)}',
      );
    }

    return PsInt64(bytes.getInt64(1, Endian.big));
  }

  /// Converts this 64-bit integer to its PackStream byte representation.
  ///
  /// Returns 9 bytes: marker (0xCB) followed by the signed 64-bit value in big-endian format.
  @override
  ByteData toByteData() {
    return ByteData(9)
      ..setUint8(0, marker)
      ..setInt64(1, value, Endian.big);
  }

  /// Checks if this 64-bit integer equals another object.
  ///
  /// Returns true if the other object is a [PsInt64] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsInt64) return false;
    return value == other.value;
  }

  /// Returns the hash code for this 64-bit integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this 64-bit integer.
  @override
  String toString() => 'PsInt64($value)';
}
