part of '../ps_data_type.dart';

/// Registry for Structure types that allows consumer libraries to register
/// their structure implementations.
class StructureRegistry {
  static final Map<int, StructureFactory> _factories = {};

  /// Registers a structure factory for a given tag byte.
  ///
  /// [tagByte] must be between 0 and 127 (inclusive).
  /// [factory] is a function that creates a Structure from the given values.
  static void register(int tagByte, StructureFactory factory) {
    if (tagByte < 0 || tagByte > 127) {
      throw ArgumentError('Tag byte must be between 0 and 127, got: $tagByte');
    }
    _factories[tagByte] = factory;
  }

  /// Unregisters a structure factory for a given tag byte.
  static void unregister(int tagByte) {
    _factories.remove(tagByte);
  }

  /// Creates a Structure from the given tag byte and values.
  ///
  /// Throws [ArgumentError] if no factory is registered for the tag byte.
  static Structure createStructure(int tagByte, List<PsDataType> values) {
    final factory = _factories[tagByte];
    if (factory == null) {
      throw ArgumentError(
        'No factory registered for tag byte: $tagByte (0x${tagByte.toRadixString(16)})',
      );
    }
    return factory(values);
  }

  /// Checks if a factory is registered for the given tag byte.
  static bool isRegistered(int tagByte) => _factories.containsKey(tagByte);

  /// Clears all registered factories. Useful for testing.
  static void clear() => _factories.clear();
}

/// Function type for creating Structure instances from parsed values.
typedef StructureFactory = Structure Function(List<PsDataType> values);

/// Abstract base class for PackStream structures.
///
/// A structure is a composite value, comprised of fields and a unique type code.
/// Structure encodings consist of a marker byte (0xB0-0xBF for 0-15 fields),
/// followed by a tag byte (0-127), followed by the field values.
///
/// This class provides the infrastructure for creating PackStream-compatible
/// structures that consumer libraries can extend to implement domain-specific
/// structures like Node, Relationship, etc.
abstract class Structure extends PsDataType<List<PsDataType>, List<Object?>> {
  /// Creates a new Structure with the given number of fields, tag byte, and values.
  ///
  /// [numberOfFields] must be between 0 and 15 (inclusive) as per PackStream spec.
  /// [tagByte] must be between 0 and 127 (inclusive).
  Structure(this.numberOfFields, this.tagByte, this.values) {
    if (numberOfFields < 0 || numberOfFields > 15) {
      throw ArgumentError(
        'Number of fields must be between 0 and 15, got: $numberOfFields',
      );
    }
    if (tagByte < 0 || tagByte > 127) {
      throw ArgumentError('Tag byte must be between 0 and 127, got: $tagByte');
    }
    // Note: We don't validate values.length == numberOfFields here
    // to allow testing invalid states. This validation happens in toByteData()
  }

  /// The number of fields in this structure (0-15).
  final int numberOfFields;

  /// The tag byte that identifies the type of this structure (0-127).
  final int tagByte;

  /// The field values of this structure.
  final List<PsDataType> values;

  @override
  int get marker {
    if (numberOfFields < 0 || numberOfFields > 15) {
      throw ArgumentError(
        'Number of fields must be between 0 and 15, got: $numberOfFields',
      );
    }
    return 0xB0 + numberOfFields;
  }

  @override
  List<PsDataType> get value => values;

  @override
  List<Object?> get dartValue => values.map((e) => e.dartValue).toList();

  @override
  ByteData toByteData() {
    if (numberOfFields != values.length) {
      throw StateError(
        'Number of fields ($numberOfFields) does not match values length (${values.length})',
      );
    }

    if (tagByte < 0 || tagByte > 127) {
      throw StateError('Tag byte must be between 0 and 127, got: $tagByte');
    }

    // Calculate total size needed
    int totalSize = 2; // marker + tag byte
    for (final value in values) {
      totalSize += value.toByteData().lengthInBytes;
    }

    final result = ByteData(totalSize);
    int offset = 0;

    // Write marker byte
    result.setUint8(offset++, marker);

    // Write tag byte
    result.setUint8(offset++, tagByte);

    // Write field values
    for (final value in values) {
      final valueBytes = value.toByteData();
      for (int i = 0; i < valueBytes.lengthInBytes; i++) {
        result.setUint8(offset++, valueBytes.getUint8(i));
      }
    }

    return result;
  }

  /// Creates a Structure from the given tag byte and parsed field values.
  ///
  /// This is used internally by the parsing logic and by the registry system.
  static Structure createFromParsedValues(
    int tagByte,
    List<PsDataType> values,
  ) {
    return StructureRegistry.createStructure(tagByte, values);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Structure) return false;
    if (runtimeType != other.runtimeType) return false;
    return numberOfFields == other.numberOfFields &&
        tagByte == other.tagByte &&
        _listEquals(values, other.values);
  }

  @override
  int get hashCode =>
      Object.hash(numberOfFields, tagByte, Object.hashAll(values));

  @override
  String toString() =>
      'Structure(fields: $numberOfFields, tag: 0x${tagByte.toRadixString(16)}, values: $values)';

  /// Helper method for comparing lists of PsDataType
  bool _listEquals(List<PsDataType> a, List<PsDataType> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Creates a Structure from Dart values.
  ///
  /// [fields] is a list of (field name, field value) pairs that will be converted
  /// to PackStream types. The field names are used for documentation/debugging
  /// but are not serialized as structures don't store field names.
  /// [structureType] is used to look up the appropriate factory in the registry.
  static Structure fromDartValues(
    List<(String, dynamic)> fields,
    Type structureType,
  ) {
    // For this implementation, we'll need the consumer to register their types
    // with a mapping from Type to tag byte. For now, we'll throw an error
    // indicating this needs to be implemented by the consumer.
    throw UnimplementedError(
      'fromDartValues requires consumer library to implement type-to-tagbyte mapping. '
      'Consider using the constructor directly or implement a factory method in your structure class.',
    );
  }
}
