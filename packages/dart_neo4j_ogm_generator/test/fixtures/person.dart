import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'person.cypher.dart';

@CypherNode(label: 'Person')
class Customer {
  final String id;
  final String name;

  const Customer({required this.id, required this.name});

  factory Customer.fromCypherMap(Map<String, dynamic> map) =>
      _$CustomerFromCypherMap(map);
}
