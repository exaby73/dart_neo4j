import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';

part 'person.cypher.dart';

@CypherNode(label: 'Person')
class Customer {
  final CypherId id;
  final String name;

  const Customer({required this.id, required this.name});

  factory Customer.fromNode(Node node) => _$CustomerFromNode(node);
}
