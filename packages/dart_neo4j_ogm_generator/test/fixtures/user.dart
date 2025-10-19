import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';

part 'user.cypher.dart';

@cypherNode
class User {
  final String id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromCypherMap(Map<String, dynamic> map) =>
      _$UserFromCypherMap(map);
}
