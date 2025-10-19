// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonUser _$JsonUserFromJson(Map<String, dynamic> json) => _JsonUser(
  id: cypherIdFromJson((json['id'] as num?)?.toInt()),
  name: json['name'] as String,
  email: json['email'] as String,
  age: (json['age'] as num?)?.toInt(),
  internalNotes: json['internalNotes'] as String?,
);

Map<String, dynamic> _$JsonUserToJson(_JsonUser instance) => <String, dynamic>{
  'id': cypherIdToJson(instance.id),
  'name': instance.name,
  'email': instance.email,
  'age': instance.age,
  'internalNotes': instance.internalNotes,
};
