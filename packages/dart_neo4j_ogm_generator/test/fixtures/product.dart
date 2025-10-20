// ignore_for_file: deprecated_member_use

import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'product.cypher.dart';

@CypherNode(includeFromNode: false)
class Product {
  final CypherId id;

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
