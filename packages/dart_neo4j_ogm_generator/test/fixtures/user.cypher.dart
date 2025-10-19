// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CypherGenerator
// **************************************************************************

part of 'user.dart';

// Generated extension for User
extension UserCypher on User {
  /// Returns a map of parameter names to values for Cypher queries.
  Map<String, dynamic> get cypherParameters {
    return {'name': name, 'email': email};
  }

  /// Returns Cypher node properties syntax string with parameter placeholders.
  String get cypherProperties {
    final props = <String>[];

    props.add('name: \$name');

    props.add('email: \$email');

    return '{${props.join(', ')}}';
  }

  /// Returns complete Cypher node syntax with variable name, label, and properties.
  /// Example: `user.toCypherWithPlaceholders('u')` returns `'(u:User {id: $id, name: $name})'`
  String toCypherWithPlaceholders(String variableName) {
    return '($variableName:$nodeLabel $cypherProperties)';
  }

  /// Returns the Neo4j node label for this User.
  String get nodeLabel => 'User';

  /// Returns the list of property names used in Cypher queries.
  List<String> get cypherPropertyNames => ['name', 'email'];

  /// Returns Cypher node properties syntax string with prefixed parameter placeholders.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherPropertiesWithPrefix('user_')` returns `'{id: $user_id, name: $user_name}'`
  String cypherPropertiesWithPrefix(String prefix) {
    final props = <String>[];

    props.add('name: \$${prefix}name');

    props.add('email: \$${prefix}email');

    return '{${props.join(', ')}}';
  }

  /// Returns a map of parameter names to values with the specified prefix.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherParametersWithPrefix('user_')` returns `{'user_id': '123', 'user_name': 'John'}`
  Map<String, dynamic> cypherParametersWithPrefix(String prefix) {
    return {'${prefix}name': name, '${prefix}email': email};
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

/// Private function to create User from Neo4j Node object.
/// Use this in a factory constructor like:
/// `factory User.fromNode(Node node) => _$UserFromNode(node);`
User _$UserFromNode(Node node) {
  final props = node.properties;

  return User(
    id: CypherId.value(node.id),

    name: props['name'] as String,

    email: props['email'] as String,
  );
}
