part of '../ps_data_type.dart';

/// Abstract base class for PackStream integer representations.
///
/// PackStream supports multiple integer representations depending on the magnitude
/// of the value to optimize for space efficiency:
///
/// - **TINY_INT** (1 byte): Values from -16 to 127
/// - **INT_8** (2 bytes): Values from -128 to -17
/// - **INT_16** (3 bytes): Values from -32,768 to -129 or 128 to 32,767
/// - **INT_32** (5 bytes): Values from -2,147,483,648 to -32,769 or 32,768 to 2,147,483,647
/// - **INT_64** (9 bytes): All other values
///
/// This class provides factory methods to automatically select the most compact
/// representation for any given integer value.
///
/// Example:
/// ```dart
/// final smallInt = PsInt.compact(42);     // Uses TINY_INT
/// final mediumInt = PsInt.compact(1000);  // Uses INT_16
/// final largeInt = PsInt.compact(1000000000); // Uses INT_32
/// ```
abstract class PsInt extends PsDataType<int, int> {
  /// Creates a new PackStream integer.
  ///
  /// This constructor should only be called by subclasses.
  const PsInt();

  /// Creates a PackStream integer using the most compact representation.
  ///
  /// This factory automatically selects the optimal integer type based on
  /// the value's magnitude to minimize the serialized size:
  ///
  /// - Values from -16 to 127: [PsTinyInt] (1 byte)
  /// - Values from -128 to -17: [PsInt8] (2 bytes)
  /// - Values from -32,768 to -129 or 128 to 32,767: [PsInt16] (3 bytes)
  /// - Values from -2,147,483,648 to -32,769 or 32,768 to 2,147,483,647: [PsInt32] (5 bytes)
  /// - All other values: [PsInt64] (9 bytes)
  ///
  /// [value] The integer value to represent.
  factory PsInt.compact(int value) {
    // Return the most compact representation of the value
    if (value >= -16 && value <= 127) {
      // For values between -16 and 127 inclusive, use TINY_INT
      return PsTinyInt(value < 0 ? 0x100 + value : value);
    } else if (value >= -128 && value <= -17) {
      // For values between -128 and -17 inclusive, use INT_8
      return PsInt8(value);
    } else if (value >= -32768 && value <= -129 ||
        value >= 128 && value <= 32767) {
      // For values between -32768 and -129 or 128 to 32767 inclusive, use INT_16
      return PsInt16(value);
    } else if (value >= -2147483648 && value <= -32769 ||
        value >= 32768 && value <= 2147483647) {
      // For values between -2147483648 and -32769 or 32768 to 2147483647 inclusive, use INT_32
      return PsInt32(value);
    } else {
      // For all other values, use INT_64
      return PsInt64(value);
    }
  }

  /// Creates a compact PackStream integer from PackStream bytes.
  ///
  /// This factory parses the bytes according to the PackStream specification
  /// and returns the appropriate integer type based on the marker byte.
  ///
  /// Supported markers:
  /// - `0x00`-`0x7F`: Positive TINY_INT
  /// - `0xF0`-`0xFF`: Negative TINY_INT
  /// - `0xC8`: INT_8 (8-bit signed integer)
  /// - `0xC9`: INT_16 (16-bit signed integer)
  /// - `0xCA`: INT_32 (32-bit signed integer)
  /// - `0xCB`: INT_64 (64-bit signed integer)
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - There are insufficient bytes for the specified integer type
  /// - The marker byte is not a valid integer marker
  factory PsInt.compactFromBytes(ByteData bytes) {
    if (bytes.buffer.lengthInBytes == 0) {
      throw ArgumentError('Bytes must not be empty');
    }

    final firstByte = bytes.getUint8(0);

    // Handle based on marker byte
    switch (firstByte) {
      // INT_8
      case 0xC8:
        if (bytes.buffer.lengthInBytes < 2) {
          throw ArgumentError('Not enough bytes for Int8');
        }
        return PsInt.compact(bytes.getInt8(1));

      // INT_16
      case 0xC9:
        if (bytes.buffer.lengthInBytes < 3) {
          throw ArgumentError('Not enough bytes for Int16');
        }
        return PsInt.compact(bytes.getInt16(1, Endian.big));

      // INT_32
      case 0xCA:
        if (bytes.buffer.lengthInBytes < 5) {
          throw ArgumentError('Not enough bytes for Int32');
        }
        return PsInt.compact(bytes.getInt32(1, Endian.big));

      // INT_64
      case 0xCB:
        if (bytes.buffer.lengthInBytes < 9) {
          throw ArgumentError('Not enough bytes for Int64');
        }
        return PsInt.compact(bytes.getInt64(1, Endian.big));

      // TINY_INT
      default:
        if ((firstByte >= 0xF0 && firstByte <= 0xFF) ||
            (firstByte >= 0x00 && firstByte <= 0x7F)) {
          // Convert to signed int if necessary
          final value = firstByte >= 0xF0 ? firstByte - 0x100 : firstByte;
          return PsInt.compact(value);
        }
        throw ArgumentError(
          'Invalid integer marker byte: 0x${firstByte.toRadixString(16)}',
        );
    }
  }

  /// Checks if this integer value equals another object.
  ///
  /// Returns true if the other object is a [PsInt] with the same integer value,
  /// regardless of the specific integer type used.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsInt) return false;
    return value == other.value;
  }

  /// Returns the hash code for this integer value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this integer value.
  @override
  String toString() => 'PsInt($value)';
}
