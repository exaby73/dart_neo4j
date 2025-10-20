import 'package:dart_bolt/dart_bolt.dart';
import 'package:dart_neo4j/src/exceptions/type_exception.dart';

/// A node in a Neo4j graph.
class Node {
  final BoltNode _boltNode;

  /// Creates a new node from a Bolt node.
  const Node._(this._boltNode);

  /// Creates a node from a Bolt node.
  factory Node.fromBolt(BoltNode boltNode) {
    return Node._(boltNode);
  }

  /// The unique identifier of the node.
  ///
  /// **Deprecated:** This property uses the legacy numeric ID which is deprecated in Neo4j 5.0+.
  /// Use [elementId] or [elementIdOrThrow] instead.
  ///
  /// See: https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id
  @Deprecated(
    'Use elementId or elementIdOrThrow instead. '
    'The id() function is deprecated in Neo4j 5.0+. '
    'See https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id',
  )
  int get id => _boltNode.id.dartValue;

  /// The element ID of the node.
  String? get elementId => _boltNode.elementId?.dartValue;

  /// The element ID of the node.
  ///
  /// Throws [StateError] if the node has no element ID.
  ///
  /// Requires Neo4j 5.0+ to be used as `elementId` is not supported in earlier versions.
  String get elementIdOrThrow => switch (_boltNode.elementId?.dartValue) {
    String value => value,
    null => throw StateError('Node has no element ID'),
  };

  /// The labels assigned to the node.
  List<String> get labels =>
      _boltNode.labels.map((label) => label.dartValue as String).toList();

  /// The properties of the node.
  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final entry in _boltNode.properties.entries) {
      result[entry.key.dartValue] = entry.value.dartValue;
    }
    return Map.unmodifiable(result);
  }

  /// Gets a property value by name.
  ///
  /// Throws [FieldNotFoundException] if the property does not exist.
  /// Throws [TypeMismatchException] if the property exists but has the wrong type.
  T getProperty<T>(String name) {
    final stringName = PsString(name);
    if (!_boltNode.properties.containsKey(stringName)) {
      throw FieldNotFoundException(
        name,
        _boltNode.properties.keys
            .map((k) => k.dartValue)
            .cast<String>()
            .toSet(),
      );
    }

    final value = _boltNode.properties[stringName]!.dartValue;
    if (value is! T) {
      throw TypeMismatchException(name, T, value.runtimeType, value);
    }

    return value;
  }

  /// Gets a property value by name, returning null if not found or wrong type.
  T? getPropertyOrNull<T>(String name) {
    try {
      return getProperty<T>(name);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the node has a property with the given name.
  bool hasProperty(String name) {
    return _boltNode.properties.containsKey(PsString(name));
  }

  /// Checks if the node has the given label.
  bool hasLabel(String label) {
    return _boltNode.labels.any((l) => l.dartValue == label);
  }

  /// The underlying Bolt node.
  BoltNode get boltNode => _boltNode;

  @override
  String toString() {
    final elementIdStr = elementId != null ? ', elementId: $elementId' : '';
    // ignore: deprecated_member_use_from_same_package
    return 'Node{id: $id$elementIdStr, labels: $labels, properties: $properties}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Node) return false;

    // Prefer elementId for comparison when available on both nodes
    if (elementId != null && other.elementId != null) {
      return elementId == other.elementId;
    }

    // Fall back to id comparison for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id == other.id;
  }

  @override
  int get hashCode {
    // Prefer elementId for hash code when available
    if (elementId != null) {
      return elementId.hashCode;
    }

    // Fall back to id for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id.hashCode;
  }
}

/// A relationship in a Neo4j graph.
class Relationship {
  final BoltRelationship _boltRelationship;

  /// Creates a new relationship from a Bolt relationship.
  const Relationship._(this._boltRelationship);

  /// Creates a relationship from a Bolt relationship.
  factory Relationship.fromBolt(BoltRelationship boltRelationship) {
    return Relationship._(boltRelationship);
  }

  /// The unique identifier of the relationship.
  ///
  /// **Deprecated:** This property uses the legacy numeric ID which is deprecated in Neo4j 5.0+.
  /// Use [elementId] or [elementIdOrThrow] instead.
  ///
  /// See: https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id
  @Deprecated(
    'Use elementId or elementIdOrThrow instead. '
    'The id() function is deprecated in Neo4j 5.0+. '
    'See https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id',
  )
  int get id => _boltRelationship.id.dartValue;

  /// The element ID of the relationship.
  String? get elementId => _boltRelationship.elementId?.dartValue;

  /// The element ID of the relationship.
  ///
  /// Throws [StateError] if the relationship has no element ID.
  ///
  /// Requires Neo4j 5.0+ to be used as `elementId` is not supported in earlier versions.
  String get elementIdOrThrow =>
      switch (_boltRelationship.elementId?.dartValue) {
        String value => value,
        null => throw StateError('Relationship has no element ID'),
      };

  /// The type of the relationship.
  String get type => _boltRelationship.type.dartValue;

  /// The identifier of the start node.
  int get startNodeId => _boltRelationship.startNodeId.dartValue;

  /// The identifier of the end node.
  int get endNodeId => _boltRelationship.endNodeId.dartValue;

  /// The properties of the relationship.
  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final entry in _boltRelationship.properties.entries) {
      result[entry.key.dartValue] = entry.value.dartValue;
    }
    return Map.unmodifiable(result);
  }

  /// Gets a property value by name.
  ///
  /// Throws [FieldNotFoundException] if the property does not exist.
  /// Throws [TypeMismatchException] if the property exists but has the wrong type.
  T getProperty<T>(String name) {
    final stringName = PsString(name);
    if (!_boltRelationship.properties.containsKey(stringName)) {
      throw FieldNotFoundException(
        name,
        _boltRelationship.properties.keys
            .map((k) => k.dartValue)
            .cast<String>()
            .toSet(),
      );
    }

    final value = _boltRelationship.properties[stringName]!.dartValue;
    if (value is! T) {
      throw TypeMismatchException(name, T, value.runtimeType, value);
    }

    return value;
  }

  /// Gets a property value by name, returning null if not found or wrong type.
  T? getPropertyOrNull<T>(String name) {
    try {
      return getProperty<T>(name);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the relationship has a property with the given name.
  bool hasProperty(String name) {
    return _boltRelationship.properties.containsKey(PsString(name));
  }

  /// The underlying Bolt relationship.
  BoltRelationship get boltRelationship => _boltRelationship;

  @override
  String toString() {
    final elementIdStr = elementId != null ? ', elementId: $elementId' : '';
    // ignore: deprecated_member_use_from_same_package
    return 'Relationship{id: $id$elementIdStr, type: $type, startNodeId: $startNodeId, endNodeId: $endNodeId, properties: $properties}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Relationship) return false;

    // Prefer elementId for comparison when available on both relationships
    if (elementId != null && other.elementId != null) {
      return elementId == other.elementId;
    }

    // Fall back to id comparison for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id == other.id;
  }

  @override
  int get hashCode {
    // Prefer elementId for hash code when available
    if (elementId != null) {
      return elementId.hashCode;
    }

    // Fall back to id for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id.hashCode;
  }
}

/// An unbound relationship (without start/end node IDs).
class UnboundRelationship {
  final BoltUnboundRelationship _boltUnboundRelationship;

  /// Creates a new unbound relationship from a Bolt unbound relationship.
  const UnboundRelationship._(this._boltUnboundRelationship);

  /// Creates an unbound relationship from a Bolt unbound relationship.
  factory UnboundRelationship.fromBolt(
    BoltUnboundRelationship boltUnboundRelationship,
  ) {
    return UnboundRelationship._(boltUnboundRelationship);
  }

  /// The unique identifier of the relationship.
  ///
  /// **Deprecated:** This property uses the legacy numeric ID which is deprecated in Neo4j 5.0+.
  ///
  /// See: https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id
  @Deprecated(
    'The id() function is deprecated in Neo4j 5.0+. '
    'See https://neo4j.com/docs/cypher-manual/5/functions/scalar/#functions-id',
  )
  int get id => _boltUnboundRelationship.id.dartValue;

  /// The element ID of the relationship.
  String? get elementId => _boltUnboundRelationship.elementId?.dartValue;

  /// The element ID of the relationship.
  ///
  /// Throws [StateError] if the relationship has no element ID.
  ///
  /// Requires Neo4j 5.0+ to be used as `elementId` is not supported in earlier versions.
  String get elementIdOrThrow =>
      switch (_boltUnboundRelationship.elementId?.dartValue) {
        String value => value,
        null => throw StateError('UnboundRelationship has no element ID'),
      };

  /// The type of the relationship.
  String get type => _boltUnboundRelationship.type.dartValue;

  /// The properties of the relationship.
  Map<String, dynamic> get properties {
    final result = <String, dynamic>{};
    for (final entry in _boltUnboundRelationship.properties.entries) {
      result[entry.key.dartValue] = entry.value.dartValue;
    }
    return Map.unmodifiable(result);
  }

  /// Gets a property value by name.
  ///
  /// Throws [FieldNotFoundException] if the property does not exist.
  /// Throws [TypeMismatchException] if the property exists but has the wrong type.
  T getProperty<T>(String name) {
    final stringName = PsString(name);
    if (!_boltUnboundRelationship.properties.containsKey(stringName)) {
      throw FieldNotFoundException(
        name,
        _boltUnboundRelationship.properties.keys
            .map((k) => k.dartValue)
            .cast<String>()
            .toSet(),
      );
    }

    final value = _boltUnboundRelationship.properties[stringName]!.dartValue;
    if (value is! T) {
      throw TypeMismatchException(name, T, value.runtimeType, value);
    }

    return value;
  }

  /// Gets a property value by name, returning null if not found or wrong type.
  T? getPropertyOrNull<T>(String name) {
    try {
      return getProperty<T>(name);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the relationship has a property with the given name.
  bool hasProperty(String name) {
    return _boltUnboundRelationship.properties.containsKey(PsString(name));
  }

  /// The underlying Bolt unbound relationship.
  BoltUnboundRelationship get boltUnboundRelationship =>
      _boltUnboundRelationship;

  @override
  String toString() {
    final elementIdStr = elementId != null ? ', elementId: $elementId' : '';
    // ignore: deprecated_member_use_from_same_package
    return 'UnboundRelationship{id: $id$elementIdStr, type: $type, properties: $properties}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UnboundRelationship) return false;

    // Prefer elementId for comparison when available on both relationships
    if (elementId != null && other.elementId != null) {
      return elementId == other.elementId;
    }

    // Fall back to id comparison for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id == other.id;
  }

  @override
  int get hashCode {
    // Prefer elementId for hash code when available
    if (elementId != null) {
      return elementId.hashCode;
    }

    // Fall back to id for backward compatibility
    // ignore: deprecated_member_use_from_same_package
    return id.hashCode;
  }
}

/// A path in a Neo4j graph, consisting of nodes and relationships.
class Path {
  final BoltPath _boltPath;
  final List<Node> _nodes;
  final List<UnboundRelationship> _relationships;

  /// Creates a new path from a Bolt path.
  Path._(this._boltPath)
    : _nodes = _boltPath.nodes
          .map((node) => Node.fromBolt(node as BoltNode))
          .toList(),
      _relationships = _boltPath.relationships
          .map(
            (rel) =>
                UnboundRelationship.fromBolt(rel as BoltUnboundRelationship),
          )
          .toList();

  /// Creates a path from a Bolt path.
  factory Path.fromBolt(BoltPath boltPath) {
    return Path._(boltPath);
  }

  /// The nodes in the path.
  List<Node> get nodes => List.unmodifiable(_nodes);

  /// The relationships in the path.
  List<UnboundRelationship> get relationships =>
      List.unmodifiable(_relationships);

  /// The length of the path (number of relationships).
  int get length => _relationships.length;

  /// Whether the path is empty (no nodes).
  bool get isEmpty => _nodes.isEmpty;

  /// Whether the path is not empty.
  bool get isNotEmpty => _nodes.isNotEmpty;

  /// The start node of the path.
  Node? get start => _nodes.isNotEmpty ? _nodes.first : null;

  /// The end node of the path.
  Node? get end => _nodes.isNotEmpty ? _nodes.last : null;

  /// The underlying Bolt path.
  BoltPath get boltPath => _boltPath;

  @override
  String toString() {
    return 'Path{length: $length, nodes: ${_nodes.length}, relationships: ${_relationships.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Path &&
        other._nodes.length == _nodes.length &&
        other._relationships.length == _relationships.length &&
        _nodesEqual(other._nodes) &&
        _relationshipsEqual(other._relationships);
  }

  bool _nodesEqual(List<Node> otherNodes) {
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i] != otherNodes[i]) return false;
    }
    return true;
  }

  bool _relationshipsEqual(List<UnboundRelationship> otherRelationships) {
    for (int i = 0; i < _relationships.length; i++) {
      if (_relationships[i] != otherRelationships[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(_nodes.length, _relationships.length);
  }
}
