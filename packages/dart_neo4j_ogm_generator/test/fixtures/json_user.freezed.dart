// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'json_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsonUser {

@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) CypherId get id; String get name; String get email;@CypherProperty(name: 'userAge') int? get age;@CypherProperty(ignore: true) String? get internalNotes;
/// Create a copy of JsonUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonUserCopyWith<JsonUser> get copyWith => _$JsonUserCopyWithImpl<JsonUser>(this as JsonUser, _$identity);

  /// Serializes this JsonUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.age, age) || other.age == age)&&(identical(other.internalNotes, internalNotes) || other.internalNotes == internalNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,age,internalNotes);

@override
String toString() {
  return 'JsonUser(id: $id, name: $name, email: $email, age: $age, internalNotes: $internalNotes)';
}


}

/// @nodoc
abstract mixin class $JsonUserCopyWith<$Res>  {
  factory $JsonUserCopyWith(JsonUser value, $Res Function(JsonUser) _then) = _$JsonUserCopyWithImpl;
@useResult
$Res call({
@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) CypherId id, String name, String email,@CypherProperty(name: 'userAge') int? age,@CypherProperty(ignore: true) String? internalNotes
});




}
/// @nodoc
class _$JsonUserCopyWithImpl<$Res>
    implements $JsonUserCopyWith<$Res> {
  _$JsonUserCopyWithImpl(this._self, this._then);

  final JsonUser _self;
  final $Res Function(JsonUser) _then;

/// Create a copy of JsonUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? age = freezed,Object? internalNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CypherId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,internalNotes: freezed == internalNotes ? _self.internalNotes : internalNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonUser].
extension JsonUserPatterns on JsonUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonUser value)  $default,){
final _that = this;
switch (_that) {
case _JsonUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonUser value)?  $default,){
final _that = this;
switch (_that) {
case _JsonUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson)  CypherId id,  String name,  String email, @CypherProperty(name: 'userAge')  int? age, @CypherProperty(ignore: true)  String? internalNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.age,_that.internalNotes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson)  CypherId id,  String name,  String email, @CypherProperty(name: 'userAge')  int? age, @CypherProperty(ignore: true)  String? internalNotes)  $default,) {final _that = this;
switch (_that) {
case _JsonUser():
return $default(_that.id,_that.name,_that.email,_that.age,_that.internalNotes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson)  CypherId id,  String name,  String email, @CypherProperty(name: 'userAge')  int? age, @CypherProperty(ignore: true)  String? internalNotes)?  $default,) {final _that = this;
switch (_that) {
case _JsonUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.age,_that.internalNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JsonUser implements JsonUser {
  const _JsonUser({@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) required this.id, required this.name, required this.email, @CypherProperty(name: 'userAge') this.age, @CypherProperty(ignore: true) this.internalNotes});
  factory _JsonUser.fromJson(Map<String, dynamic> json) => _$JsonUserFromJson(json);

@override@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) final  CypherId id;
@override final  String name;
@override final  String email;
@override@CypherProperty(name: 'userAge') final  int? age;
@override@CypherProperty(ignore: true) final  String? internalNotes;

/// Create a copy of JsonUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonUserCopyWith<_JsonUser> get copyWith => __$JsonUserCopyWithImpl<_JsonUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JsonUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.age, age) || other.age == age)&&(identical(other.internalNotes, internalNotes) || other.internalNotes == internalNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,age,internalNotes);

@override
String toString() {
  return 'JsonUser(id: $id, name: $name, email: $email, age: $age, internalNotes: $internalNotes)';
}


}

/// @nodoc
abstract mixin class _$JsonUserCopyWith<$Res> implements $JsonUserCopyWith<$Res> {
  factory _$JsonUserCopyWith(_JsonUser value, $Res Function(_JsonUser) _then) = __$JsonUserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(toJson: cypherIdToJson, fromJson: cypherIdFromJson) CypherId id, String name, String email,@CypherProperty(name: 'userAge') int? age,@CypherProperty(ignore: true) String? internalNotes
});




}
/// @nodoc
class __$JsonUserCopyWithImpl<$Res>
    implements _$JsonUserCopyWith<$Res> {
  __$JsonUserCopyWithImpl(this._self, this._then);

  final _JsonUser _self;
  final $Res Function(_JsonUser) _then;

/// Create a copy of JsonUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? age = freezed,Object? internalNotes = freezed,}) {
  return _then(_JsonUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CypherId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,internalNotes: freezed == internalNotes ? _self.internalNotes : internalNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
