part of '../ps_data_type.dart';

/// Represents a 32-bit signed integer in the PackStream format.
///
/// INT_32 uses 5 bytes total:
/// - Marker byte: `0xCA`
/// - Value bytes: 32-bit signed integer in big-endian format (-2,147,483,648 to 2,147,483,647)
///
/// This representation is automatically chosen by [PsInt.compact] for values
/// in the ranges -2,147,483,648 to -32,769 or 32,768 to 2,147,483,647 inclusive.
///
/// Example:
/// ```dart
/// final int32 = PsInt32(1000000);
/// print(int32.toBytes()); // [0xCA, 0x00, 0x0F, 0x42, 0x40]
/// ```
final class PsInt32 extends PsInt {
  /// Creates a new PackStream 32-bit integer.
  ///
  /// [value] The integer value to represent. Must be in the range -2,147,483,648 to 2,147,483,647.
  PsInt32(this.value);

  /// The 32-bit signed integer value.
  @override
  final int value;

  /// Returns the integer value.
  @override
  int get dartValue => value;

  /// Returns the marker byte for 32-bit integers (0xCA).
  @override
  int get marker => 0xCA;

  /// Creates a [PsInt32] from PackStream bytes.
  ///
  /// The bytes must contain exactly 5 bytes:
  /// - First byte: marker (0xCA)
  /// - Next 4 bytes: signed 32-bit integer value in big-endian format
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes don't contain exactly 5 bytes
  /// - The first byte is not the correct marker (0xCA)
  factory PsInt32.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Invalid marker byte: 0xempty');
    }

    if (bytes.lengthInBytes != 5) {
      throw ArgumentError('Not enough bytes for Int32');
    }

    if (bytes.getUint8(0) != 0xCA) {
      throw ArgumentError(
        'Invalid marker byte: 0x${bytes.getUint8(0).toRadixString(16)}',
      );
    }

    return PsInt32(bytes.getInt32(1, Endian.big));
  }

  /// Converts this 32-bit integer to its PackStream byte representation.
  ///
  /// Returns 5 bytes: marker (0xCA) followed by the signed 32-bit value in big-endian format.
  @override
  ByteData toByteData() {
    return ByteData(5)
      ..setUint8(0, marker)
      ..setInt32(1, value, Endian.big);
  }

  /// Checks if this 32-bit integer equals another object.
  ///
  /// Returns true if the other object is a [PsInt32] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsInt32) return false;
    return value == other.value;
  }

  /// Returns the hash code for this 32-bit integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this 32-bit integer.
  @override
  String toString() => 'PsInt32($value)';
}
