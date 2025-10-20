// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CypherGenerator
// **************************************************************************

part of 'freezed_user.dart';

// Generated extension for FreezedUser
extension FreezedUserCypher on FreezedUser {
  /// Returns a map of parameter names to values for Cypher queries.
  Map<String, dynamic> get cypherParameters {
    return {'name': name, 'emailAddress': email, 'bio': bio};
  }

  /// Returns Cypher node properties syntax string with parameter placeholders.
  String get cypherProperties {
    final props = <String>[];

    props.add('name: \$name');

    props.add('emailAddress: \$emailAddress');

    props.add('bio: \$bio');

    return '{${props.join(', ')}}';
  }

  /// Returns complete Cypher node syntax with variable name, label, and properties.
  /// Example: `user.toCypherWithPlaceholders('u')` returns `'(u:User {id: $id, name: $name})'`
  String toCypherWithPlaceholders(String variableName) {
    return '($variableName:${nodeLabel} $cypherProperties)';
  }

  /// The Neo4j node label for this FreezedUser.
  static const String nodeLabel = 'FreezedUser';

  /// Record of property names used in Cypher queries.
  /// Each field name corresponds to the Dart property name, with the Cypher property name as its value.
  static const ({String name, String email, String bio}) cypherPropertyNames = (
    name: 'name',

    email: 'emailAddress',

    bio: 'bio',
  );

  /// Returns Cypher node properties syntax string with prefixed parameter placeholders.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherPropertiesWithPrefix('user_')` returns `'{id: $user_id, name: $user_name}'`
  String cypherPropertiesWithPrefix(String prefix) {
    final props = <String>[];

    props.add('name: \$${prefix}name');

    props.add('emailAddress: \$${prefix}emailAddress');

    props.add('bio: \$${prefix}bio');

    return '{${props.join(', ')}}';
  }

  /// Returns a map of parameter names to values with the specified prefix.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.cypherParametersWithPrefix('user_')` returns `{'user_id': '123', 'user_name': 'John'}`
  Map<String, dynamic> cypherParametersWithPrefix(String prefix) {
    return {
      '${prefix}name': name,

      '${prefix}emailAddress': email,

      '${prefix}bio': bio,
    };
  }

  /// Returns complete Cypher node syntax with variable name, label, and prefixed properties.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: `user.toCypherWithPlaceholdersWithPrefix('u', 'user_')` returns `'(u:User {id: $user_id, name: $user_name})'`
  String toCypherWithPlaceholdersWithPrefix(
    String variableName,
    String prefix,
  ) {
    return '($variableName:${nodeLabel} ${cypherPropertiesWithPrefix(prefix)})';
  }
}
