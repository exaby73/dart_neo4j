// ignore_for_file: deprecated_member_use

import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';

part 'hybrid_user.cypher.dart';

@cypherNode
class HybridUser {
  final CypherId legacyId;
  final CypherElementId elementId;
  final String username;

  const HybridUser({
    required this.legacyId,
    required this.elementId,
    required this.username,
  });

  factory HybridUser.fromNode(Node node) => _$HybridUserFromNode(node);
}
