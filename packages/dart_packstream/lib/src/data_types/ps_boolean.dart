part of '../ps_data_type.dart';

/// Represents a boolean value in the PackStream format.
///
/// Boolean values are encoded within a single marker byte:
/// - `true` is encoded as `0xC3`
/// - `false` is encoded as `0xC2`
///
/// Example:
/// ```dart
/// final trueValue = PsBoolean(true);
/// final falseValue = PsBoolean(false);
///
/// print(trueValue.toBytes());  // [0xC3]
/// print(falseValue.toBytes()); // [0xC2]
/// ```
final class PsBoolean extends PsDataType<bool, bool> {
  /// Creates a new PackStream boolean value.
  ///
  /// [value] The boolean value to represent.
  PsBoolean(this.value);

  /// The underlying boolean value.
  @override
  final bool value;

  /// Returns the underlying boolean value.
  @override
  bool get dartValue => value;

  /// Returns the marker byte for this boolean value.
  ///
  /// Returns `0xC3` for true, `0xC2` for false.
  @override
  int get marker => value ? 0xC3 : 0xC2;

  /// Creates a [PsBoolean] from PackStream bytes.
  ///
  /// The bytes must contain exactly one byte that is either:
  /// - `0xC2` for false
  /// - `0xC3` for true
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The bytes contain more than 1 byte
  /// - The single byte is not a valid boolean marker
  factory PsBoolean.fromPackStreamBytes(ByteData bytes) {
    if (bytes.lengthInBytes == 0) {
      throw ArgumentError('Bytes must not be empty');
    }

    if (bytes.lengthInBytes != 1) {
      throw ArgumentError(
        'Invalid number of bytes for Boolean: ${bytes.lengthInBytes}',
      );
    }

    final markerByte = bytes.getUint8(0);
    if (markerByte == 0xC2) {
      return PsBoolean(false);
    } else if (markerByte == 0xC3) {
      return PsBoolean(true);
    } else {
      throw ArgumentError(
        'Invalid marker byte for Boolean: 0x${markerByte.toRadixString(16)}',
      );
    }
  }

  /// Converts this boolean value to its PackStream byte representation.
  ///
  /// Returns a single byte: `0xC3` for true, `0xC2` for false.
  @override
  ByteData toByteData() {
    return ByteData(1)..setUint8(0, marker);
  }

  /// Checks if this boolean value equals another object.
  ///
  /// Returns true if the other object is a [PsBoolean] with the same value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsBoolean) return false;
    return value == other.value;
  }

  /// Returns the hash code for this boolean value.
  @override
  int get hashCode => value.hashCode;

  /// Returns a string representation of this boolean value.
  @override
  String toString() => 'PsBoolean($value)';
}
