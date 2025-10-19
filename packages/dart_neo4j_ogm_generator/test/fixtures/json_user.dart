import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:dart_neo4j/dart_neo4j.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'json_user.freezed.dart';
part 'json_user.g.dart';
part 'json_user.cypher.dart';

@freezed
@CypherNode()
abstract class JsonUser with _$JsonUser {
  const factory JsonUser({
    @JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson)
    required CypherId id,
    required String name,
    required String email,
    @CypherProperty(name: 'userAge') int? age,
    @CypherProperty(ignore: true) String? internalNotes,
  }) = _JsonUser;

  factory JsonUser.fromJson(Map<String, dynamic> json) =>
      _$JsonUserFromJson(json);

  factory JsonUser.fromNode(Node node) => _$JsonUserFromNode(node);
}
