// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CypherGenerator
// **************************************************************************

part of 'product.dart';

// Generated extension for Product
extension ProductCypher on Product {
  /// Returns a map of parameter names to values for Cypher queries.
  Map<String, dynamic> get cypherParameters {
    return {'id': id, 'productName': name, 'price': price};
  }

  /// Returns Cypher node properties syntax string with parameter placeholders.
  String get cypherProperties {
    final props = <String>[];

    props.add('id: \$id');

    props.add('productName: \$productName');

    props.add('price: \$price');

    return '{${props.join(', ')}}';
  }

  /// Converts this Product to a map for Cypher queries.
  Map<String, dynamic> toCypherMap() {
    return cypherParameters;
  }

  /// Returns complete Cypher node syntax with variable name, label, and properties.
  /// Example: user.toCypherWithPlaceholders('u') returns '(u:User {id: $id, name: $name})'
  String toCypherWithPlaceholders(String variableName) {
    return '($variableName:$nodeLabel $cypherProperties)';
  }

  /// Returns the Neo4j node label for this Product.
  String get nodeLabel => 'Product';

  /// Returns the list of property names used in Cypher queries.
  List<String> get cypherPropertyNames => ['id', 'productName', 'price'];

  /// Returns Cypher node properties syntax string with prefixed parameter placeholders.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: user.cypherPropertiesWithPrefix('user_') returns '{id: $user_id, name: $user_name}'
  String cypherPropertiesWithPrefix(String prefix) {
    final props = <String>[];

    props.add('id: \$${prefix}id');

    props.add('productName: \$${prefix}productName');

    props.add('price: \$${prefix}price');

    return '{${props.join(', ')}}';
  }

  /// Returns a map of parameter names to values with the specified prefix.
  /// This helps avoid parameter name collisions in complex queries.
  /// Example: user.cypherParametersWithPrefix('user_') returns {'user_id': '123', 'user_name': 'John'}
  Map<String, dynamic> cypherParametersWithPrefix(String prefix) {
    return {
      '${prefix}id': id,

      '${prefix}productName': name,

      '${prefix}price': price,
    };
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
