import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';

part 'modern_user.cypher.dart';

@cypherNode
class ModernUser {
  final CypherElementId elementId;
  final String name;
  final String email;

  const ModernUser({
    required this.elementId,
    required this.name,
    required this.email,
  });

  factory ModernUser.fromNode(Node node) => _$ModernUserFromNode(node);
}
