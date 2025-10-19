// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CypherGenerator
// **************************************************************************

part of 'person.dart';

// Generated extension for Customer
extension CustomerCypher on Customer {
  /// Returns a map of parameter names to values for Cypher queries.
  Map<String, dynamic> get cypherParameters {
    return {'id': id, 'name': name};
  }

  /// Returns Cypher node properties syntax string with parameter placeholders.
  String get cypherProperties {
    final props = <String>[];

    props.add('id: \$id');

    props.add('name: \$name');

    return '{${props.join(', ')}}';
  }

  /// Converts this Customer to a map for Cypher queries.
  Map<String, dynamic> toCypherMap() {
    return cypherParameters;
  }

  /// Returns complete Cypher node syntax with variable name, label, and properties.
  /// Example: user.toCypherWithPlaceholders('u') returns '(u:User {id: $id, name: $name})'
  String toCypherWithPlaceholders(String variableName) {
    return '($variableName:$nodeLabel $cypherProperties)';
  }

  /// Returns the Neo4j node label for this Customer.
  String get nodeLabel => 'Person';

  /// Returns the list of property names used in Cypher queries.
  List<String> get cypherPropertyNames => ['id', 'name'];

  /// Returns Cypher node properties syntax string with prefixed parameter placeholders.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: user.cypherPropertiesWithPrefix('user_') returns '{id: $user_id, name: $user_name}'
  String cypherPropertiesWithPrefix(String prefix) {
    final props = <String>[];

    props.add('id: \$${prefix}id');

    props.add('name: \$${prefix}name');

    return '{${props.join(', ')}}';
  }

  /// Returns a map of parameter names to values with the specified prefix.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: user.cypherParametersWithPrefix('user_') returns {'user_id': '123', 'user_name': 'John'}
  Map<String, dynamic> cypherParametersWithPrefix(String prefix) {
    return {'${prefix}id': id, '${prefix}name': name};
  }

  /// Returns complete Cypher node syntax with variable name, label, and prefixed properties.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: user.toCypherWithPlaceholdersWithPrefix('u', 'user_') returns '(u:User {id: $user_id, name: $user_name})'
  String toCypherWithPlaceholdersWithPrefix(
    String variableName,
    String prefix,
  ) {
    return '($variableName:$nodeLabel ${cypherPropertiesWithPrefix(prefix)})';
  }
}

/// Private function to create Customer from Cypher result map.
/// Use this in a factory constructor like:
/// `factory Customer.fromCypherMap(Map<String, dynamic> map) => _$CustomerFromCypherMap(map);`
Customer _$CustomerFromCypherMap(Map<String, dynamic> map) {
  return Customer(id: map['id'] as String, name: map['name'] as String);
}
