part of '../ps_data_type.dart';

/// Represents a 16-bit signed integer in the PackStream format.
///
/// INT_16 uses 3 bytes total:
/// - Marker byte: `0xC9`
/// - Value bytes: 16-bit signed integer in big-endian format (-32,768 to 32,767)
///
/// This representation is automatically chosen by [PsInt.compact] for values
/// in the ranges -32,768 to -129 or 128 to 32,767 inclusive.
///
/// Example:
/// ```dart
/// final int16 = PsInt16(1000);
/// print(int16.toBytes()); // [0xC9, 0x03, 0xE8]
/// ```
final class PsInt16 extends PsInt {
  /// Creates a new PackStream 16-bit integer.
  ///
  /// [value] The integer value to represent. Must be in the range -32,768 to 32,767.
  PsInt16(this.value);

  /// The 16-bit signed integer value.
  @override
  final int value;

  /// Returns the integer value.
  @override
  int get dartValue => value;

  /// Returns the marker byte for 16-bit integers (0xC9).
  @override
  int get marker => 0xC9;

  /// Creates a [PsInt16] from PackStream bytes.
  ///
  /// The bytes must contain exactly 3 bytes:
  /// - First byte: marker (0xC9)
  /// - Next 2 bytes: signed 16-bit integer value in big-endian format
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes don't contain exactly 3 bytes
  /// - The first byte is not the correct marker (0xC9)
  factory PsInt16.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Invalid marker byte: 0xempty');
    }

    if (bytes.lengthInBytes != 3) {
      throw ArgumentError('Not enough bytes for Int16');
    }

    if (bytes.getUint8(0) != 0xC9) {
      throw ArgumentError(
        'Invalid marker byte: 0x${bytes.getUint8(0).toRadixString(16)}',
      );
    }

    return PsInt16(bytes.getInt16(1, Endian.big));
  }

  /// Converts this 16-bit integer to its PackStream byte representation.
  ///
  /// Returns 3 bytes: marker (0xC9) followed by the signed 16-bit value in big-endian format.
  @override
  ByteData toByteData() {
    return ByteData(3)
      ..setUint8(0, marker)
      ..setInt16(1, value, Endian.big);
  }

  /// Checks if this 16-bit integer equals another object.
  ///
  /// Returns true if the other object is a [PsInt16] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsInt16) return false;
    return value == other.value;
  }

  /// Returns the hash code for this 16-bit integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this 16-bit integer.
  @override
  String toString() => 'PsInt16($value)';
}
