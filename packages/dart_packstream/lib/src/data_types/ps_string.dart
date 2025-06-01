part of '../ps_data_type.dart';

/// Represents a UTF-8 encoded string in the PackStream format.
///
/// Strings are represented as UTF-8 encoded bytes with variable-length encoding
/// based on the byte length of the UTF-8 representation:
///
/// - **Tiny String** (1 + N bytes): 0-15 bytes, marker `0x80`-`0x8F`
/// - **String 8** (2 + N bytes): 16-255 bytes, marker `0xD0`
/// - **String 16** (3 + N bytes): 256-65,535 bytes, marker `0xD1`
/// - **String 32** (5 + N bytes): 65,536-2,147,483,647 bytes, marker `0xD2`
///
/// The size represents the byte count of the UTF-8 encoded data, not the character count.
///
/// Example:
/// ```dart
/// final str = PsString("Hello, World!");
/// final unicode = PsString("Größenmaßstäbe"); // German text with umlauts
/// print(str.toBytes()); // [0x8D, 0x48, 0x65, 0x6C, 0x6C, 0x6F, ...]
/// ```
final class PsString extends PsDataType<String, String> {
  /// Creates a new PackStream string value.
  ///
  /// [value] The string value to represent. Will be UTF-8 encoded when serialized.
  PsString(this.value);

  /// Creates a [PsString] from PackStream bytes.
  ///
  /// Parses the bytes according to the PackStream string format and decodes
  /// the UTF-8 content to a Dart string.
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The marker byte is not a valid string marker
  /// - There are insufficient bytes for the specified string length
  /// - The UTF-8 content is invalid
  PsString.fromPackStreamBytes(ByteData bytes) {
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (data.isEmpty) {
      throw ArgumentError('String data must not be empty');
    }

    final markerByte = data.first;
    int size;
    int offset;

    if (markerByte >= 0x80 && markerByte <= 0x8F) {
      // Tiny string (length in low nibble)
      size = markerByte & 0x0F;
      offset = 1;
    } else if (markerByte == 0xD0) {
      // 8-bit size
      if (data.length < 2) {
        throw ArgumentError('Not enough bytes for String with 8-bit size');
      }
      size = bytes.getUint8(1);
      offset = 2;
    } else if (markerByte == 0xD1) {
      // 16-bit size
      if (data.length < 3) {
        throw ArgumentError('Not enough bytes for String with 16-bit size');
      }
      size = bytes.getUint16(1, Endian.big);
      offset = 3;
    } else if (markerByte == 0xD2) {
      // 32-bit size
      if (data.length < 5) {
        throw ArgumentError('Not enough bytes for String with 32-bit size');
      }
      size = bytes.getUint32(1, Endian.big);
      offset = 5;
    } else {
      throw ArgumentError(
        'Invalid marker byte for String: 0x${markerByte.toRadixString(16)}',
      );
    }

    if (data.length < offset + size) {
      throw ArgumentError('Not enough bytes for String data');
    }

    final utf8Bytes = data.sublist(offset, offset + size);
    value = utf8.decode(utf8Bytes);
  }

  /// The UTF-8 string value.
  @override
  late final String value;

  /// Returns the string value.
  @override
  String get dartValue => value;

  /// Returns the appropriate marker byte based on the UTF-8 byte length.
  ///
  /// Automatically selects the most compact representation:
  /// - 0-15 bytes: Tiny string marker (0x80 + length)
  /// - 16-255 bytes: String 8 marker (0xD0)
  /// - 256-65,535 bytes: String 16 marker (0xD1)
  /// - 65,536+ bytes: String 32 marker (0xD2)
  int get _appropriateMarker {
    final utf8Bytes = utf8.encode(value);
    final length = utf8Bytes.length;

    if (length < 16) {
      return 0x80 + length; // Tiny string
    } else if (length <= 0xFF) {
      return 0xD0; // 8-bit size
    } else if (length <= 0xFFFF) {
      return 0xD1; // 16-bit size
    } else {
      return 0xD2; // 32-bit size
    }
  }

  /// Returns the marker byte for this string.
  @override
  int get marker => _appropriateMarker;

  /// Converts this string to its PackStream byte representation.
  ///
  /// The string is UTF-8 encoded and the appropriate size encoding is used
  /// based on the byte length of the UTF-8 representation.
  ///
  /// Returns the complete PackStream representation including marker, size, and UTF-8 content.
  @override
  ByteData toByteData() {
    final utf8Bytes = utf8.encode(value);
    final length = utf8Bytes.length;
    late final ByteData bytes;

    if (length < 16) {
      // Tiny string
      bytes = ByteData(1 + length);
      bytes.setUint8(0, 0x80 + length);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(1 + i, utf8Bytes[i]);
      }
    } else if (length <= 0xFF) {
      // 8-bit size
      bytes = ByteData(2 + length);
      bytes.setUint8(0, 0xD0);
      bytes.setUint8(1, length);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(2 + i, utf8Bytes[i]);
      }
    } else if (length <= 0xFFFF) {
      // 16-bit size
      bytes = ByteData(3 + length);
      bytes.setUint8(0, 0xD1);
      bytes.setUint16(1, length, Endian.big);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(3 + i, utf8Bytes[i]);
      }
    } else {
      // 32-bit size
      bytes = ByteData(5 + length);
      bytes.setUint8(0, 0xD2);
      bytes.setUint32(1, length, Endian.big);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(5 + i, utf8Bytes[i]);
      }
    }

    return bytes;
  }

  /// Checks if this string equals another object.
  ///
  /// Returns true if the other object is a [PsString] with the same string value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsString) return false;
    return value == other.value;
  }

  /// Returns the hash code for this string value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this PackStream string.
  @override
  String toString() => 'PsString("$value")';
}
