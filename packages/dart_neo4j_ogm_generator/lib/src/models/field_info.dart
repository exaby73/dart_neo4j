/// Data model for holding field metadata during code generation.
library;

/// Holds metadata about a field in a class annotated with @cypherNode.
class FieldInfo {
  const FieldInfo({
    required this.name,
    required this.type,
    required this.cypherName,
    required this.isIgnored,
    this.isCypherIdField = false,
    this.isCypherElementIdField = false,
  });

  /// The original field name in the Dart class.
  final String name;

  /// The Dart type of the field.
  final String type;

  /// The name to use in Cypher queries (from @CypherProperty or original name).
  final String cypherName;

  /// Whether this field should be ignored in Cypher generation.
  final bool isIgnored;

  /// Whether this field is a CypherId field (legacy integer ID).
  final bool isCypherIdField;

  /// Whether this field is a CypherElementId field (Neo4j 5.0+ string element ID).
  final bool isCypherElementIdField;

  /// Whether this field is an ID field (either CypherId or CypherElementId).
  bool get isIdField => isCypherIdField || isCypherElementIdField;

  /// Converts the field info to a map for template rendering.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'cypherName': cypherName,
      'isIgnored': isIgnored,
      'isIdField': isIdField,
      'isCypherIdField': isCypherIdField,
      'isCypherElementIdField': isCypherElementIdField,
    };
  }
}
