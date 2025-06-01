part of '../ps_data_type.dart';

/// Represents a double-precision floating-point value in the PackStream format.
///
/// FLOAT uses 9 bytes total:
/// - Marker byte: `0xC1`
/// - Value bytes: 64-bit IEEE 754 double-precision floating-point number in big-endian format
///
/// Floats are used for representing fractions and decimals. The format follows
/// the IEEE 754 "double format" bit layout with:
/// - Bit 63: Sign bit
/// - Bits 62-52: Exponent (11 bits)
/// - Bits 51-0: Mantissa/Significand (52 bits)
///
/// Example:
/// ```dart
/// final float = PsFloat(3.14159);
/// final pi = PsFloat(Math.pi);
/// print(float.toBytes()); // [0xC1, ...8 bytes...]
/// ```
final class PsFloat extends PsDataType<double, double> {
  /// Creates a new PackStream floating-point value.
  ///
  /// [value] The double-precision floating-point value to represent.
  PsFloat(this.value);

  /// The double-precision floating-point value.
  @override
  final double value;

  /// Returns the marker byte for floating-point values (0xC1).
  @override
  int get marker => 0xC1;

  /// Returns the floating-point value.
  @override
  double get dartValue => value;

  /// Creates a [PsFloat] from PackStream bytes.
  ///
  /// The bytes must contain exactly 9 bytes:
  /// - First byte: marker (0xC1)
  /// - Next 8 bytes: IEEE 754 double-precision value in big-endian format
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes don't contain exactly 9 bytes
  /// - The first byte is not the correct marker (0xC1)
  factory PsFloat.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Bytes must not be empty');
    }

    if (bytes.lengthInBytes != 9) {
      throw ArgumentError(
        'Invalid number of bytes for Float: ${bytes.lengthInBytes}',
      );
    }

    if (bytes.getUint8(0) != 0xC1) {
      throw ArgumentError(
        'Invalid marker byte for Float: 0x${bytes.getUint8(0).toRadixString(16)}',
      );
    }

    return PsFloat(bytes.getFloat64(1, Endian.big));
  }

  /// Converts this floating-point value to its PackStream byte representation.
  ///
  /// Returns 9 bytes: marker (0xC1) followed by the IEEE 754 double-precision
  /// value in big-endian format.
  @override
  ByteData toByteData() {
    return ByteData(9)
      ..setUint8(0, marker)
      ..setFloat64(1, value, Endian.big);
  }

  /// Checks if this floating-point value equals another object.
  ///
  /// Returns true if the other object is a [PsFloat] with the same value.
  /// Note: This uses standard floating-point equality which may not work
  /// as expected for NaN values or values that are very close but not identical.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsFloat) return false;
    return value == other.value;
  }

  /// Returns the hash code for this floating-point value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this floating-point value.
  @override
  String toString() => 'PsFloat($value)';
}
