part of '../ps_data_type.dart';

/// Represents a byte array in the PackStream format.
///
/// Bytes are arrays of byte values used to transmit raw binary data.
/// The size represents the number of bytes contained. Unlike strings,
/// there is no separate encoding for byte arrays containing fewer than 16 bytes.
///
/// Available representations:
/// - **Bytes 8** (2 + N bytes): 0-255 bytes, marker `0xCC`
/// - **Bytes 16** (3 + N bytes): 256-65,535 bytes, marker `0xCD`
/// - **Bytes 32** (5 + N bytes): 65,536-2,147,483,647 bytes, marker `0xCE`
///
/// This class implements [Iterable<int>] to allow easy iteration over the byte values.
///
/// Example:
/// ```dart
/// final bytes = PsBytes(Uint8List.fromList([1, 2, 3, 255]));
/// final empty = PsBytes(Uint8List(0));
/// print(bytes.toBytes()); // [0xCC, 0x04, 0x01, 0x02, 0x03, 0xFF]
///
/// // Iterate over bytes
/// for (final byte in bytes) {
///   print('Byte: $byte');
/// }
/// ```
final class PsBytes extends PsDataType<Uint8List, Uint8List>
    with Iterable<int> {
  /// Creates a new PackStream byte array.
  ///
  /// [value] The byte array to represent as a [Uint8List].
  PsBytes(this.value);

  /// Provides an iterator over the byte values.
  ///
  /// This allows the [PsBytes] to be used in for-in loops and other
  /// iterable operations.
  @override
  Iterator<int> get iterator => value.iterator;

  /// Returns the byte array.
  @override
  Uint8List get dartValue => value;

  /// Creates a [PsBytes] from PackStream bytes.
  ///
  /// Parses the bytes according to the PackStream bytes format and extracts
  /// the raw byte content.
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The marker byte is not a valid bytes marker (0xCC, 0xCD, or 0xCE)
  /// - There are insufficient bytes for the specified byte array length
  PsBytes.fromPackStreamBytes(ByteData bytes) {
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (data.isEmpty) {
      throw ArgumentError('Bytes must not be empty');
    }

    final markerByte = data.first;
    if (markerByte != 0xCC && markerByte != 0xCD && markerByte != 0xCE) {
      throw ArgumentError(
        'Invalid marker byte for Bytes: 0x${markerByte.toRadixString(16)}',
      );
    }

    int size;
    int offset;

    switch (markerByte) {
      case 0xCC: // 8-bit size
        if (data.length < 2) {
          throw ArgumentError('Not enough bytes for Bytes with 8-bit size');
        }
        size = bytes.getUint8(1);
        offset = 2;
      case 0xCD: // 16-bit size
        if (data.length < 3) {
          throw ArgumentError('Not enough bytes for Bytes with 16-bit size');
        }
        size = bytes.getUint16(1, Endian.big);
        offset = 3;
      case 0xCE: // 32-bit size
        if (data.length < 5) {
          throw ArgumentError('Not enough bytes for Bytes with 32-bit size');
        }
        size = bytes.getUint32(1, Endian.big);
        offset = 5;
      default:
        throw ArgumentError(
          'Invalid marker byte for Bytes: 0x${markerByte.toRadixString(16)}',
        );
    }

    if (data.length < offset + size) {
      throw ArgumentError('Not enough bytes for Bytes data');
    }

    value = Uint8List.fromList(data.sublist(offset, offset + size));
  }

  /// The byte array value.
  @override
  late final Uint8List value;

  /// Returns the appropriate marker byte based on the byte array length.
  ///
  /// Automatically selects the most compact representation:
  /// - 0-255 bytes: Bytes 8 marker (0xCC)
  /// - 256-65,535 bytes: Bytes 16 marker (0xCD)
  /// - 65,536+ bytes: Bytes 32 marker (0xCE)
  int get _appropriateMarker {
    final length = value.length;
    if (length <= 0xFF) {
      return 0xCC; // 8-bit size
    } else if (length <= 0xFFFF) {
      return 0xCD; // 16-bit size
    } else {
      return 0xCE; // 32-bit size
    }
  }

  /// Returns the marker byte for this byte array.
  @override
  int get marker => _appropriateMarker;

  /// Converts this byte array to its PackStream byte representation.
  ///
  /// The appropriate size encoding is used based on the length of the byte array.
  ///
  /// Returns the complete PackStream representation including marker, size, and byte content.
  @override
  ByteData toByteData() {
    final length = value.length;
    late final ByteData bytes;

    if (length <= 0xFF) {
      // 8-bit size
      bytes = ByteData(2 + length)
        ..setUint8(0, 0xCC)
        ..setUint8(1, length);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(2 + i, value[i]);
      }
    } else if (length <= 0xFFFF) {
      // 16-bit size
      bytes = ByteData(3 + length)
        ..setUint8(0, 0xCD)
        ..setUint16(1, length, Endian.big);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(3 + i, value[i]);
      }
    } else {
      // 32-bit size
      bytes = ByteData(5 + length)
        ..setUint8(0, 0xCE)
        ..setUint32(1, length, Endian.big);

      for (var i = 0; i < length; i++) {
        bytes.setUint8(5 + i, value[i]);
      }
    }

    return bytes;
  }

  /// Checks if this byte array equals another object.
  ///
  /// Returns true if the other object is a [PsBytes] with the same byte content.
  /// Performs element-by-element comparison of the byte arrays.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsBytes) return false;
    if (value.length != other.value.length) return false;
    for (int i = 0; i < value.length; i++) {
      if (value[i] != other.value[i]) return false;
    }
    return true;
  }

  /// Returns the hash code for this byte array.
  ///
  /// Uses [Object.hashAll] to create a hash from all byte values.
  @override
  int get hashCode => Object.hashAll(value);

  /// Returns a string representation of this byte array.
  ///
  /// Shows the byte values as a comma-separated list in square brackets.
  @override
  String toString() => 'PsBytes([${value.join(', ')}])';
}
