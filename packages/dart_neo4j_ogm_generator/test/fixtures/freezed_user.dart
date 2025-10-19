import 'package:dart_neo4j_ogm/dart_neo4j_ogm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'freezed_user.freezed.dart';
part 'freezed_user.cypher.dart';

@freezed
@CypherNode(includeFromNode: false)
abstract class FreezedUser with _$FreezedUser {
  const factory FreezedUser({
    required CypherId id,
    required String name,
    @CypherProperty(name: 'emailAddress') required String email,
    @CypherProperty(ignore: true) required String password,
    String? bio,
  }) = _FreezedUser;
}
