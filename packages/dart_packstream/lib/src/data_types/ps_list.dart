part of '../ps_data_type.dart';

/// Represents a heterogeneous sequence of values in the PackStream format.
///
/// Lists permit a mixture of types within the same list and can contain any
/// PackStream data types. The size of a list denotes the number of items
/// within that list, rather than the total packed byte size.
///
/// Available representations:
/// - **Tiny List** (1 + content bytes): 0-15 items, marker `0x90`-`0x9F`
/// - **List 8** (2 + content bytes): 16-255 items, marker `0xD4`
/// - **List 16** (3 + content bytes): 256-65,535 items, marker `0xD5`
/// - **List 32** (5 + content bytes): 65,536-2,147,483,647 items, marker `0xD6`
///
/// This class extends [ListBase<PsDataType>] to provide standard Dart list operations.
///
/// Example:
/// ```dart
/// final list = PsList([
///   PsInt.compact(1),
///   PsString("hello"),
///   PsBoolean(true),
/// ]);
///
/// // Access elements
/// print(list[0]); // PsInt(1)
/// print(list.length); // 3
///
/// // Iterate
/// for (final item in list) {
///   print(item.dartValue);
/// }
/// ```
final class PsList extends PsDataType<List<PsDataType>, List<Object?>>
    with ListBase<PsDataType> {
  /// Creates a new PackStream list.
  ///
  /// [_values] The list of PackStream data types to contain.
  PsList(this._values);

  /// The internal list of PackStream values.
  final List<PsDataType> _values;

  /// Provides an iterator over the list items.
  @override
  Iterator<PsDataType> get iterator => _values.iterator;

  /// Returns the list of PackStream values.
  @override
  List<PsDataType> get value => _values;

  /// Returns the list of Dart values by converting each PackStream value.
  @override
  List<Object?> get dartValue => _values.map((e) => e.dartValue).toList();

  /// Returns the appropriate marker byte based on the list size.
  ///
  /// Automatically selects the most compact representation:
  /// - 0-15 items: Tiny list marker (0x90 + size)
  /// - 16-255 items: List 8 marker (0xD4)
  /// - 256-65,535 items: List 16 marker (0xD5)
  /// - 65,536+ items: List 32 marker (0xD6)
  @override
  int get marker {
    final size = _values.length;
    if (size < 16) {
      return 0x90 + size;
    }
    if (size <= 0xFF) {
      return 0xD4;
    }
    if (size <= 0xFFFF) {
      return 0xD5;
    }
    return 0xD6;
  }

  /// Converts this list to its PackStream byte representation.
  ///
  /// The appropriate size encoding is used based on the number of items.
  /// Each item is serialized in order after the marker and size.
  ///
  /// Returns the complete PackStream representation including marker, size, and all item content.
  @override
  ByteData toByteData() {
    final size = _values.length;
    final sizeBytes = _getSizeBytes(size);

    // Calculate total size needed
    int totalSize = sizeBytes.lengthInBytes;
    for (final item in _values) {
      totalSize += item.toByteData().lengthInBytes;
    }

    final result = ByteData(totalSize);
    int offset = 0;

    // Write marker and size
    for (int i = 0; i < sizeBytes.lengthInBytes; i++) {
      result.setUint8(offset++, sizeBytes.getUint8(i));
    }

    // Write items
    for (final item in _values) {
      final itemBytes = item.toByteData();
      for (int i = 0; i < itemBytes.lengthInBytes; i++) {
        result.setUint8(offset++, itemBytes.getUint8(i));
      }
    }

    return result;
  }

  /// Creates the size bytes portion of the PackStream representation.
  ///
  /// [size] The number of items in the list.
  ///
  /// Returns the marker and size bytes according to the PackStream specification.
  ByteData _getSizeBytes(int size) {
    if (size < 16) {
      return ByteData(1)..setUint8(0, 0x90 + size);
    } else if (size <= 0xFF) {
      final bytes = ByteData(2);
      bytes.setUint8(0, 0xD4);
      bytes.setUint8(1, size);
      return bytes;
    } else if (size <= 0xFFFF) {
      final bytes = ByteData(3);
      bytes.setUint8(0, 0xD5);
      bytes.setUint16(1, size, Endian.big);
      return bytes;
    } else {
      final bytes = ByteData(5);
      bytes.setUint8(0, 0xD6);
      bytes.setUint32(1, size, Endian.big);
      return bytes;
    }
  }

  /// Creates a [PsList] from PackStream bytes.
  ///
  /// Parses the bytes according to the PackStream list format and recursively
  /// parses each item in the list.
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The marker byte is not a valid list marker
  /// - There are insufficient bytes for the specified number of items
  /// - Any item in the list cannot be parsed
  factory PsList.fromPackStreamBytes(ByteData bytes) {
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (data.isEmpty) {
      throw ArgumentError('List data must not be empty');
    }

    final markerByte = data.first;
    int size;
    int offset;

    if (markerByte >= 0x90 && markerByte <= 0x9F) {
      // Tiny list (0-15 items)
      size = markerByte - 0x90;
      offset = 1;
    } else if (markerByte == 0xD4) {
      // 8-bit list
      if (data.length < 2) {
        throw ArgumentError('Not enough bytes for List with 8-bit size');
      }
      size = bytes.getUint8(1);
      offset = 2;
    } else if (markerByte == 0xD5) {
      // 16-bit list
      if (data.length < 3) {
        throw ArgumentError('Not enough bytes for List with 16-bit size');
      }
      size = bytes.getUint16(1, Endian.big);
      offset = 3;
    } else if (markerByte == 0xD6) {
      // 32-bit list
      if (data.length < 5) {
        throw ArgumentError('Not enough bytes for List with 32-bit size');
      }
      size = bytes.getUint32(1, Endian.big);
      offset = 5;
    } else {
      throw ArgumentError(
        'Invalid marker byte for List: 0x${markerByte.toRadixString(16)}',
      );
    }

    final items = <PsDataType>[];

    int currentOffset = offset;
    for (int i = 0; i < size; i++) {
      if (currentOffset >= bytes.lengthInBytes) {
        throw ArgumentError('Insufficient bytes for list items');
      }

      // Create a view of the remaining bytes
      final itemBytes = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + currentOffset,
        bytes.lengthInBytes - currentOffset,
      );

      final item = PsDataType.fromPackStreamBytes(itemBytes);
      items.add(item);

      // Move offset forward by the size of the item
      final itemSize = item.toByteData().lengthInBytes;
      if (itemSize <= 0) {
        throw ArgumentError('Invalid item size: $itemSize');
      }
      currentOffset += itemSize;
    }

    return PsList(items);
  }

  /// Gets the item at the specified index.
  ///
  /// [index] The zero-based index of the item to retrieve.
  ///
  /// Returns the PackStream data type at the specified index.
  @override
  PsDataType operator [](int index) => _values[index];

  /// Sets the item at the specified index.
  ///
  /// [index] The zero-based index of the item to set.
  /// [value] The PackStream data type to set at the specified index.
  @override
  void operator []=(int index, PsDataType value) {
    _values[index] = value;
  }

  /// Returns the number of items in this list.
  @override
  int get length => _values.length;

  /// Sets the length of this list.
  ///
  /// If the new length is greater than the current length, the list is
  /// extended with null values. If shorter, items are removed from the end.
  @override
  set length(int newLength) {
    _values.length = newLength;
  }

  /// Checks if this list equals another object.
  ///
  /// Returns true if the other object is a [PsList] with the same items
  /// in the same order. Performs element-by-element comparison.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsList) return false;
    if (_values.length != other._values.length) return false;
    for (int i = 0; i < _values.length; i++) {
      if (_values[i] != other._values[i]) return false;
    }
    return true;
  }

  /// Returns the hash code for this list.
  ///
  /// Uses [Object.hashAll] to create a hash from all list items.
  @override
  int get hashCode => Object.hashAll(_values);

  /// Returns a string representation of this list.
  @override
  String toString() => 'PsList($_values)';
}
