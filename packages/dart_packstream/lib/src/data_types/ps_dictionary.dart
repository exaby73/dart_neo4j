part of '../ps_data_type.dart';

/// Represents a collection of key-value entries in the PackStream format.
///
/// A Dictionary is a list containing key-value entries where:
/// - Keys must be strings ([PsString])
/// - Values can be any PackStream data type
/// - Can contain multiple instances of the same key (last value wins)
/// - Permits a mixture of value types
///
/// The size of a Dictionary denotes the number of key-value entries within
/// that dictionary, not the total packed byte size.
///
/// Available representations:
/// - **Tiny Dictionary** (1 + content bytes): 0-15 entries, marker `0xA0`-`0xAF`
/// - **Dictionary 8** (2 + content bytes): 16-255 entries, marker `0xD8`
/// - **Dictionary 16** (3 + content bytes): 256-65,535 entries, marker `0xD9`
/// - **Dictionary 32** (5 + content bytes): 65,536-2,147,483,647 entries, marker `0xDA`
///
/// This class extends [MapBase<PsString, PsDataType>] to provide standard Dart map operations.
///
/// Example:
/// ```dart
/// final dict = PsDictionary({
///   PsString("name"): PsString("Alice"),
///   PsString("age"): PsInt.compact(30),
///   PsString("active"): PsBoolean(true),
/// });
///
/// // Access values
/// print(dict[PsString("name")]); // PsString("Alice")
/// print(dict.dartValue); // {"name": "Alice", "age": 30, "active": true}
/// ```
final class PsDictionary
    extends PsDataType<Map<PsString, PsDataType>, Map<String, Object?>>
    with MapBase<PsString, PsDataType> {
  /// Creates a new PackStream dictionary.
  ///
  /// [values] A map of key-value pairs. Keys can be [PsString] or will be
  /// converted to [PsString]. Values can be [PsDataType] or will be converted
  /// using [PsDataType.fromValue].
  PsDictionary(Map<dynamic, dynamic> values) {
    _values = {};

    // When using the constructor directly, the expectation is that keys are PsString
    // Any non-PsString keys should be handled by the fromDictionary helper method
    for (final entry in values.entries) {
      final key = entry.key as PsString;
      final value = entry.value is PsDataType
          ? entry.value as PsDataType
          : PsDataType.fromValue(entry.value);

      _values[key] = value;
    }
  }

  /// The internal map of PackStream key-value pairs.
  late final Map<PsString, PsDataType> _values;

  /// Returns the map of PackStream key-value pairs.
  @override
  Map<PsString, PsDataType> get value => _values;

  /// Returns the map of Dart key-value pairs by converting each PackStream key and value.
  @override
  Map<String, Object?> get dartValue =>
      _values.map((key, value) => MapEntry(key.value, value.dartValue));

  /// Gets the value associated with the given key.
  ///
  /// [key] The key to look up. Can be a [PsString] or any other type.
  ///
  /// Returns the associated [PsDataType] value, or null if the key is not found.
  @override
  PsDataType? operator [](Object? key) {
    return _values[key];
  }

  /// Sets the value associated with the given key.
  ///
  /// [key] The key to associate with the value. Must be a [PsString].
  /// [value] The value to associate with the key. Must be a [PsDataType].
  @override
  void operator []=(PsString key, PsDataType value) {
    _values[key] = value;
  }

  /// Removes all key-value pairs from this dictionary.
  @override
  void clear() {
    _values.clear();
  }

  /// Returns an iterable of all keys in this dictionary.
  @override
  Iterable<PsString> get keys => _values.keys;

  /// Removes the entry associated with the given key.
  ///
  /// [key] The key to remove. Can be a [String] or [PsString].
  ///
  /// Returns the removed value, or null if the key was not found.
  @override
  PsDataType? remove(Object? key) {
    if (key is String) {
      final psKey = _values.keys.firstWhere(
        (k) => k.value == key,
        orElse: () => PsString(''),
      );
      if (psKey.value.isNotEmpty) {
        return _values.remove(psKey);
      }
    } else if (key is PsString) {
      return _values.remove(key);
    }
    return null;
  }

  /// Returns the appropriate marker byte based on the dictionary size.
  ///
  /// Automatically selects the most compact representation:
  /// - 0-15 entries: Tiny dictionary marker (0xA0 + size)
  /// - 16-255 entries: Dictionary 8 marker (0xD8)
  /// - 256-65,535 entries: Dictionary 16 marker (0xD9)
  /// - 65,536+ entries: Dictionary 32 marker (0xDA)
  @override
  int get marker {
    final size = _values.length;
    if (size < 16) {
      return 0xA0 + size;
    }
    if (size <= 0xFF) {
      return 0xD8;
    }
    if (size <= 0xFFFF) {
      return 0xD9;
    }
    return 0xDA;
  }

  /// Converts this dictionary to its PackStream byte representation.
  ///
  /// The appropriate size encoding is used based on the number of entries.
  /// Each key-value pair is serialized in [key, value, key, value] order
  /// after the marker and size.
  ///
  /// Returns the complete PackStream representation including marker, size, and all entry content.
  @override
  ByteData toByteData() {
    final size = _values.length;
    final sizeBytes = _getSizeBytes(size);

    // Calculate total size needed
    int totalSize = sizeBytes.lengthInBytes;
    for (final entry in _values.entries) {
      final keyBytes = entry.key.toByteData();
      final valueBytes = entry.value.toByteData();
      totalSize += keyBytes.lengthInBytes + valueBytes.lengthInBytes;
    }

    final result = ByteData(totalSize);
    int offset = 0;

    // Write marker and size
    for (int i = 0; i < sizeBytes.lengthInBytes; i++) {
      result.setUint8(offset++, sizeBytes.getUint8(i));
    }

    // Write key-value pairs
    for (final entry in _values.entries) {
      final keyBytes = entry.key.toByteData();
      final valueBytes = entry.value.toByteData();

      // Write key
      for (int i = 0; i < keyBytes.lengthInBytes; i++) {
        result.setUint8(offset++, keyBytes.getUint8(i));
      }

      // Write value
      for (int i = 0; i < valueBytes.lengthInBytes; i++) {
        result.setUint8(offset++, valueBytes.getUint8(i));
      }
    }

    return result;
  }

  /// Creates the size bytes portion of the PackStream representation.
  ///
  /// [size] The number of key-value entries in the dictionary.
  ///
  /// Returns the marker and size bytes according to the PackStream specification.
  ByteData _getSizeBytes(int size) {
    if (size < 16) {
      return ByteData(1)..setUint8(0, 0xA0 + size);
    } else if (size <= 0xFF) {
      final bytes = ByteData(2);
      bytes.setUint8(0, 0xD8);
      bytes.setUint8(1, size);
      return bytes;
    } else if (size <= 0xFFFF) {
      final bytes = ByteData(3);
      bytes.setUint8(0, 0xD9);
      bytes.setUint16(1, size, Endian.big);
      return bytes;
    } else {
      final bytes = ByteData(5);
      bytes.setUint8(0, 0xDA);
      bytes.setUint32(1, size, Endian.big);
      return bytes;
    }
  }

  /// Creates a [PsDictionary] from PackStream bytes.
  ///
  /// Parses the bytes according to the PackStream dictionary format and recursively
  /// parses each key-value pair. Keys must be strings according to the PackStream specification.
  ///
  /// If there are multiple instances of the same key, the last seen value for that key is used.
  ///
  /// [bytes] The PackStream bytes to parse.
  ///
  /// Throws [ArgumentError] if:
  /// - The bytes are empty
  /// - The marker byte is not a valid dictionary marker
  /// - There are insufficient bytes for the specified number of entries
  /// - Any key is not a string
  /// - Any key or value cannot be parsed
  factory PsDictionary.fromPackStreamBytes(ByteData bytes) {
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (data.isEmpty) {
      throw ArgumentError('Dictionary data must not be empty');
    }

    final markerByte = data.first;
    int size;
    int offset;

    if (markerByte >= 0xA0 && markerByte <= 0xAF) {
      // Tiny dictionary (0-15 entries)
      size = markerByte - 0xA0;
      offset = 1;
    } else if (markerByte == 0xD8) {
      // 8-bit dictionary
      if (data.length < 2) {
        throw ArgumentError('Not enough bytes for Dictionary with 8-bit size');
      }
      size = bytes.getUint8(1);
      offset = 2;
    } else if (markerByte == 0xD9) {
      // 16-bit dictionary
      if (data.length < 3) {
        throw ArgumentError('Not enough bytes for Dictionary with 16-bit size');
      }
      size = bytes.getUint16(1, Endian.big);
      offset = 3;
    } else if (markerByte == 0xDA) {
      // 32-bit dictionary
      if (data.length < 5) {
        throw ArgumentError('Not enough bytes for Dictionary with 32-bit size');
      }
      size = bytes.getUint32(1, Endian.big);
      offset = 5;
    } else {
      throw ArgumentError(
        'Invalid marker byte for Dictionary: 0x${markerByte.toRadixString(16)}',
      );
    }

    final entries = <PsString, PsDataType>{};

    int currentOffset = offset;
    for (int i = 0; i < size; i++) {
      if (currentOffset >= bytes.lengthInBytes) {
        throw ArgumentError('Insufficient bytes for dictionary entries');
      }

      // Determine the first byte of the key to check if it's a string marker
      final firstKeyByte = bytes.getUint8(currentOffset);

      // Check if the first byte is a valid string marker
      final isValidStringMarker =
          (firstKeyByte >= 0x80 && firstKeyByte <= 0x8F) ||
          firstKeyByte == 0xD0 ||
          firstKeyByte == 0xD1 ||
          firstKeyByte == 0xD2;

      if (!isValidStringMarker) {
        throw ArgumentError(
          'Dictionary keys must be strings, found marker: 0x${firstKeyByte.toRadixString(16)}',
        );
      }

      // Parse the key size and calculate the total key bytes (including marker)
      int keySize;
      int keyHeaderSize;

      if (firstKeyByte >= 0x80 && firstKeyByte <= 0x8F) {
        // Tiny string, size is in low nibble
        keySize = firstKeyByte & 0x0F;
        keyHeaderSize = 1;
      } else if (firstKeyByte == 0xD0) {
        // 8-bit size string
        if (currentOffset + 1 >= bytes.lengthInBytes) {
          throw ArgumentError(
            'Insufficient bytes for string key with 8-bit size',
          );
        }
        keySize = bytes.getUint8(currentOffset + 1);
        keyHeaderSize = 2;
      } else if (firstKeyByte == 0xD1) {
        // 16-bit size string
        if (currentOffset + 2 >= bytes.lengthInBytes) {
          throw ArgumentError(
            'Insufficient bytes for string key with 16-bit size',
          );
        }
        keySize = bytes.getUint16(currentOffset + 1, Endian.big);
        keyHeaderSize = 3;
      } else {
        // 0xD2
        // 32-bit size string
        if (currentOffset + 4 >= bytes.lengthInBytes) {
          throw ArgumentError(
            'Insufficient bytes for string key with 32-bit size',
          );
        }
        keySize = bytes.getUint32(currentOffset + 1, Endian.big);
        keyHeaderSize = 5;
      }

      // Check if there's enough remaining bytes for the key content
      if (currentOffset + keyHeaderSize + keySize > bytes.lengthInBytes) {
        throw ArgumentError('Insufficient bytes for string key content');
      }

      // Extract the string key bytes
      final keyByteData = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + currentOffset,
        keyHeaderSize + keySize,
      );

      // Parse the key
      final key = PsDataType.fromPackStreamBytes(keyByteData) as PsString;

      // Move past the key bytes
      currentOffset += keyHeaderSize + keySize;

      if (currentOffset >= bytes.lengthInBytes) {
        throw ArgumentError('Insufficient bytes for dictionary value');
      }

      // Read value
      final valueBytes = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + currentOffset,
        bytes.lengthInBytes - currentOffset,
      );

      final value = PsDataType.fromPackStreamBytes(valueBytes);
      entries[key] = value;

      // Get the size of the value and advance the offset
      final valueSize = value.toByteData().lengthInBytes;
      if (valueSize <= 0) {
        throw ArgumentError('Invalid value size: $valueSize');
      }
      currentOffset += valueSize;
    }

    return PsDictionary(entries);
  }

  /// Checks if this dictionary equals another object.
  ///
  /// Returns true if the other object is a [PsDictionary] with the same
  /// key-value pairs. The order of entries does not matter.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PsDictionary) return false;
    if (_values.length != other._values.length) return false;
    for (final entry in _values.entries) {
      if (!other._values.containsKey(entry.key) ||
          other._values[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// Returns the hash code for this dictionary.
  ///
  /// Creates an order-independent hash by XORing the hash codes of all key-value pairs.
  @override
  int get hashCode {
    // Create a hash that's order-independent for dictionaries
    int hash = 0;
    for (final entry in _values.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  /// Returns a string representation of this dictionary.
  @override
  String toString() => 'PsDictionary($_values)';
}
