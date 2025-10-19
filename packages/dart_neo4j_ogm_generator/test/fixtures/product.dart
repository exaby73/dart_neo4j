import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'product.cypher.dart';

@CypherNode(includeFromCypherMap: false)
class Product {
  final String id;

  @CypherProperty(name: 'productName')
  final String name;

  @CypherProperty(ignore: true)
  final String internalCode;

  final double? price;

  const Product({
    required this.id,
    required this.name,
    required this.internalCode,
    this.price,
  });
}
