/// Annotation for marking Dart classes that should generate Cypher node methods.
class CypherNode {
  /// Creates a CypherNode annotation.
  ///
  /// [label] is the optional Neo4j node label. If not provided,
  /// the class name will be used as the label.
  /// [includeFromCypherMap] determines whether to generate the fromCypherMap helper function.
  const CypherNode({this.label, this.includeFromCypherMap = true});

  /// The Neo4j node label to use in generated Cypher queries.
  /// If null, the class name will be used.
  final String? label;

  /// Whether to generate the fromCypherMap helper function.
  /// If true, the class must have a factory constructor named `fromCypherMap`.
  /// If false, no fromCypherMap helper will be generated.
  final bool includeFromCypherMap;
}

/// Const instance of CypherNode annotation for convenience.
const cypherNode = CypherNode();
