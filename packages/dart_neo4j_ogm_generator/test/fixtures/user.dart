import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';

part 'user.cypher.dart';

@cypherNode
class User {
  final CypherId id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromNode(Node node) => _$UserFromNode(node);
}
