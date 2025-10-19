/// Annotation for marking Dart classes that should generate Cypher node methods.
class CypherNode {
  /// Creates a CypherNode annotation.
  ///
  /// [label] is the optional Neo4j node label. If not provided,
  /// the class name will be used as the label.
  /// [includeFromNode] determines whether to generate the fromNode helper function.
  const CypherNode({this.label, this.includeFromNode = true});

  /// The Neo4j node label to use in generated Cypher queries.
  /// If null, the class name will be used.
  final String? label;

  /// Whether to generate the fromNode helper function.
  /// If true, the class must have a factory constructor named `fromNode`.
  /// If false, no fromNode helper will be generated.
  final bool includeFromNode;
}

/// Const instance of CypherNode annotation for convenience.
const cypherNode = CypherNode();
