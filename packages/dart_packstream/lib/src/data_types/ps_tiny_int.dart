part of '../ps_data_type.dart';

/// Represents a tiny integer in the PackStream format.
///
/// TINY_INT is the most space-efficient integer representation, using only
/// a single byte to encode both the type and value. It can represent:
/// - Positive values: 0 to 127 (encoded as `0x00` to `0x7F`)
/// - Negative values: -16 to -1 (encoded as `0xF0` to `0xFF`)
///
/// This is automatically chosen by [PsInt.compact] for values in the range
/// -16 to 127 inclusive.
///
/// Example:
/// ```dart
/// final positive = PsTinyInt(42);   // Encoded as 0x2A
/// final negative = PsTinyInt(-5);   // Encoded as 0xFB
/// ```
final class PsTinyInt extends PsInt {
  /// Creates a new PackStream tiny integer.
  ///
  /// [_value] The raw byte value used for encoding. For positive values
  /// (0-127), this is the value itself. For negative values (-16 to -1),
  /// this is the value + 256 (e.g., -1 becomes 255/0xFF).
  PsTinyInt(this._value);

  /// The raw byte value used for encoding.
  final int _value;

  /// Returns the signed integer value represented by this tiny int.
  ///
  /// Converts the raw byte value back to a signed 8-bit integer.
  @override
  int get value => _value.toSigned(8);

  /// Returns the signed integer value.
  @override
  int get dartValue => value;

  /// Returns the marker byte for this tiny integer.
  ///
  /// For TINY_INT, the marker byte is the value itself.
  @override
  int get marker => _value;

  /// Creates a [PsTinyInt] from PackStream bytes.
  ///
  /// The bytes must contain exactly one byte that represents a valid
  /// TINY_INT marker (0x00-0x7F for positive values, 0xF0-0xFF for negative).
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes don't contain exactly 1 byte
  /// - The marker byte is not a valid TINY_INT marker
  factory PsTinyInt.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes != 1) {
      throw ArgumentError(
        'Invalid number of bytes for TinyInt: ${bytes.lengthInBytes}',
      );
    }

    final marker = bytes.getUint8(0);
    if (!(marker >= 0xF0 && marker <= 0xFF) &&
        !(marker >= 0x00 && marker <= 0x7F)) {
      throw ArgumentError('Invalid marker for TinyInt: $marker');
    }

    return PsTinyInt(marker);
  }

  /// Converts this tiny integer to its PackStream byte representation.
  ///
  /// Returns a single byte containing the signed value.
  @override
  ByteData toByteData() {
    return ByteData(1)..setInt8(0, value);
  }

  /// Checks if this tiny integer equals another object.
  ///
  /// Returns true if the other object is a [PsTinyInt] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsTinyInt) return false;
    return value == other.value;
  }

  /// Returns the hash code for this tiny integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this tiny integer.
  @override
  String toString() => 'PsTinyInt($value)';
}
