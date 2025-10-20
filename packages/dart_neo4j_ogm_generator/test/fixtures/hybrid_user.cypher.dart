// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CypherGenerator
// **************************************************************************

part of 'hybrid_user.dart';

// Generated extension for HybridUser
extension HybridUserCypher on HybridUser {
  /// Returns a map of parameter names to values for Cypher queries.
  Map<String, dynamic> get cypherParameters {
    return {'username': username};
  }

  /// Returns Cypher node properties syntax string with parameter placeholders.
  String get cypherProperties {
    final props = <String>[];

    props.add('username: \$username');

    return '{${props.join(', ')}}';
  }

  /// Returns complete Cypher node syntax with variable name, label, and properties.
  /// Example: `user.toCypherWithPlaceholders('u')` returns `'(u:User {id: $id, name: $name})'`
  String toCypherWithPlaceholders(String variableName) {
    return '($variableName:$nodeLabel $cypherProperties)';
  }

  /// Returns the Neo4j node label for this HybridUser.
  String get nodeLabel => 'HybridUser';

  /// Returns the list of property names used in Cypher queries.
  List<String> get cypherPropertyNames => ['username'];

  /// Returns Cypher node properties syntax string with prefixed parameter placeholders.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherPropertiesWithPrefix('user_')` returns `'{id: $user_id, name: $user_name}'`
  String cypherPropertiesWithPrefix(String prefix) {
    final props = <String>[];

    props.add('username: \$${prefix}username');

    return '{${props.join(', ')}}';
  }

  /// Returns a map of parameter names to values with the specified prefix.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherParametersWithPrefix('user_')` returns `{'user_id': '123', 'user_name': 'John'}`
  Map<String, dynamic> cypherParametersWithPrefix(String prefix) {
    return {'${prefix}username': username};
  }

  /// Returns complete Cypher node syntax with variable name, label, and prefixed properties.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.toCypherWithPlaceholdersWithPrefix('u', 'user_')` returns `'(u:User {id: $user_id, name: $user_name})'`
  String toCypherWithPlaceholdersWithPrefix(
    String variableName,
    String prefix,
  ) {
    return '($variableName:$nodeLabel ${cypherPropertiesWithPrefix(prefix)})';
  }
}

/// Private function to create HybridUser from Neo4j Node object.
/// Use this in a factory constructor like:
/// `factory HybridUser.fromNode(Node node) => _$HybridUserFromNode(node);`
HybridUser _$HybridUserFromNode(Node node) {
  final props = node.properties;

  return HybridUser(
    legacyId: CypherId.value(node.id),

    elementId: CypherElementId.value(node.elementIdOrThrow),

    username: props['username'] as String,
  );
}
