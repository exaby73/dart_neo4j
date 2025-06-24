import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j/src/exceptions/type_exception.dart';
import 'package:dart_neo4j/src/types/neo4j_types.dart';

/// A record containing the result data from a Neo4j query.
class Record {
  final List<String> _keys;
  final List<dynamic> _values;
  final Map<String, dynamic> _fieldMap;

  /// Creates a new record from field names and values.
  Record._(this._keys, this._values)
      : _fieldMap = Map.fromIterables(_keys, _values);

  /// Creates a record from Bolt record message data.
  factory Record.fromBolt(List<String> keys, List<dynamic> values) {
    if (keys.length != values.length) {
      throw ArgumentError('Keys and values length mismatch: ${keys.length} != ${values.length}');
    }

    final convertedValues = values.map(_convertBoltValue).toList();
    return Record._(keys, convertedValues);
  }

  /// Creates a record from a data map.
  factory Record.fromData(Map<String, dynamic> data, List<String> keys) {
    final values = keys.map((key) => data[key]).toList();
    return Record._(keys, values);
  }

  /// Converts a Bolt value to its Dart equivalent.
  static dynamic _convertBoltValue(dynamic value) {
    // Handle direct Bolt types
    if (value is BoltNode) {
      return Node.fromBolt(value);
    } else if (value is BoltRelationship) {
      return Relationship.fromBolt(value);
    } else if (value is BoltUnboundRelationship) {
      return UnboundRelationship.fromBolt(value);
    } else if (value is BoltPath) {
      return Path.fromBolt(value);
    }

    // Handle PsDataType wrapped values
    if (value is PsDataType) {
      final dartValue = value.dartValue;
      
      // Convert Bolt-specific types to Neo4j types
      if (dartValue is BoltNode) {
        return Node.fromBolt(dartValue);
      } else if (dartValue is BoltRelationship) {
        return Relationship.fromBolt(dartValue);
      } else if (dartValue is BoltUnboundRelationship) {
        return UnboundRelationship.fromBolt(dartValue);
      } else if (dartValue is BoltPath) {
        return Path.fromBolt(dartValue);
      }

      return dartValue;
    }

    return value;
  }

  /// The field names in this record.
  List<String> get keys => List.unmodifiable(_keys);

  /// The field values in this record.
  List<dynamic> get values => List.unmodifiable(_values);

  /// The number of fields in this record.
  int get length => _keys.length;

  /// Whether this record is empty (no fields).
  bool get isEmpty => _keys.isEmpty;

  /// Whether this record is not empty.
  bool get isNotEmpty => _keys.isNotEmpty;

  /// Checks if this record contains a field with the given name.
  bool containsKey(String key) {
    return _fieldMap.containsKey(key);
  }

  /// Gets the value at the given index.
  ///
  /// Throws [RangeError] if the index is out of range.
  dynamic operator [](dynamic keyOrIndex) {
    if (keyOrIndex is String) {
      return _fieldMap[keyOrIndex];
    } else if (keyOrIndex is int) {
      if (keyOrIndex < 0 || keyOrIndex >= _values.length) {
        throw RangeError.index(keyOrIndex, _values, 'index');
      }
      return _values[keyOrIndex];
    } else {
      throw ArgumentError('Key must be String or int, got ${keyOrIndex.runtimeType}');
    }
  }

  /// Gets a string value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  String getString(String key) {
    return _getTypedValue<String>(key);
  }

  /// Gets a string value by field name, returning null if not found.
  String? getStringOrNull(String key) {
    return _getTypedValueOrNull<String>(key);
  }

  /// Gets an integer value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  int getInt(String key) {
    return _getTypedValue<int>(key);
  }

  /// Gets an integer value by field name, returning null if not found.
  int? getIntOrNull(String key) {
    return _getTypedValueOrNull<int>(key);
  }

  /// Gets a double value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  double getDouble(String key) {
    return _getTypedValue<double>(key);
  }

  /// Gets a double value by field name, returning null if not found.
  double? getDoubleOrNull(String key) {
    return _getTypedValueOrNull<double>(key);
  }

  /// Gets a boolean value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  bool getBool(String key) {
    return _getTypedValue<bool>(key);
  }

  /// Gets a boolean value by field name, returning null if not found.
  bool? getBoolOrNull(String key) {
    return _getTypedValueOrNull<bool>(key);
  }

  /// Gets a numeric value (int or double) by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  num getNum(String key) {
    return _getTypedValue<num>(key);
  }

  /// Gets a numeric value (int or double) by field name, returning null if not found.
  num? getNumOrNull(String key) {
    return _getTypedValueOrNull<num>(key);
  }

  /// Gets a list value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  List<T> getList<T>(String key) {
    final value = _getTypedValue<List>(key);
    return value.cast<T>();
  }

  /// Gets a list value by field name, returning null if not found.
  List<T>? getListOrNull<T>(String key) {
    final value = _getTypedValueOrNull<List>(key);
    return value?.cast<T>();
  }

  /// Gets a map value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  Map<String, T> getMap<T>(String key) {
    final value = _getTypedValue<Map>(key);
    return value.cast<String, T>();
  }

  /// Gets a map value by field name, returning null if not found.
  Map<String, T>? getMapOrNull<T>(String key) {
    final value = _getTypedValueOrNull<Map>(key);
    return value?.cast<String, T>();
  }

  /// Gets a node value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  Node getNode(String key) {
    return _getTypedValue<Node>(key);
  }

  /// Gets a node value by field name, returning null if not found.
  Node? getNodeOrNull(String key) {
    return _getTypedValueOrNull<Node>(key);
  }

  /// Gets a relationship value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  Relationship getRelationship(String key) {
    return _getTypedValue<Relationship>(key);
  }

  /// Gets a relationship value by field name, returning null if not found.
  Relationship? getRelationshipOrNull(String key) {
    return _getTypedValueOrNull<Relationship>(key);
  }

  /// Gets an unbound relationship value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  UnboundRelationship getUnboundRelationship(String key) {
    return _getTypedValue<UnboundRelationship>(key);
  }

  /// Gets an unbound relationship value by field name, returning null if not found.
  UnboundRelationship? getUnboundRelationshipOrNull(String key) {
    return _getTypedValueOrNull<UnboundRelationship>(key);
  }

  /// Gets a path value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  Path getPath(String key) {
    return _getTypedValue<Path>(key);
  }

  /// Gets a path value by field name, returning null if not found.
  Path? getPathOrNull(String key) {
    return _getTypedValueOrNull<Path>(key);
  }

  /// Gets a typed value by field name.
  ///
  /// Throws [FieldNotFoundException] if the field does not exist.
  /// Throws [UnexpectedNullException] if the field is null.
  /// Throws [TypeMismatchException] if the field has the wrong type.
  T get<T>(String key) {
    return _getTypedValue<T>(key);
  }

  /// Gets a typed value by field name, returning null if not found or wrong type.
  T? getOrNull<T>(String key) {
    return _getTypedValueOrNull<T>(key);
  }

  /// Internal method to get a typed value.
  T _getTypedValue<T>(String key) {
    if (!_fieldMap.containsKey(key)) {
      throw FieldNotFoundException(key, _fieldMap.keys.toSet());
    }

    final value = _fieldMap[key];
    
    // Special handling for dynamic type - allow null values
    if (T == dynamic) {
      return value as T;
    }
    
    if (value == null) {
      throw UnexpectedNullException(key, T);
    }

    if (value is! T) {
      throw TypeMismatchException(key, T, value.runtimeType, value);
    }

    return value;
  }

  /// Internal method to get a typed value or null.
  T? _getTypedValueOrNull<T>(String key) {
    try {
      return _getTypedValue<T>(key);
    } catch (e) {
      return null;
    }
  }

  /// Converts this record to a map.
  Map<String, dynamic> asMap() {
    return Map.unmodifiable(_fieldMap);
  }

  @override
  String toString() {
    return 'Record{length: $length, ${_fieldMap.toString()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record &&
        other._keys.length == _keys.length &&
        _keysEqual(other._keys) &&
        _valuesEqual(other._values);
  }

  bool _keysEqual(List<String> otherKeys) {
    for (int i = 0; i < _keys.length; i++) {
      if (_keys[i] != otherKeys[i]) return false;
    }
    return true;
  }

  bool _valuesEqual(List<dynamic> otherValues) {
    for (int i = 0; i < _values.length; i++) {
      if (_values[i] != otherValues[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(_keys.length, _values.length);
  }
}