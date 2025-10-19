/// Annotation for controlling field-level Cypher generation behavior.
class CypherProperty {
  /// Creates a CypherProperty annotation.
  ///
  /// [ignore] when true, excludes this field from Cypher generation.
  /// [name] specifies a custom property name to use in Cypher queries.
  const CypherProperty({this.ignore = false, this.name});

  /// Whether to ignore this field in Cypher generation.
  final bool ignore;

  /// Custom property name to use in Cypher queries.
  /// If null, the field name will be used.
  final String? name;
}
