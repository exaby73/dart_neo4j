// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'freezed_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FreezedUser {

 CypherId get id; String get name;@CypherProperty(name: 'emailAddress') String get email;@CypherProperty(ignore: true) String get password; String? get bio;
/// Create a copy of FreezedUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreezedUserCopyWith<FreezedUser> get copyWith => _$FreezedUserCopyWithImpl<FreezedUser>(this as FreezedUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreezedUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.bio, bio) || other.bio == bio));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,password,bio);

@override
String toString() {
  return 'FreezedUser(id: $id, name: $name, email: $email, password: $password, bio: $bio)';
}


}

/// @nodoc
abstract mixin class $FreezedUserCopyWith<$Res>  {
  factory $FreezedUserCopyWith(FreezedUser value, $Res Function(FreezedUser) _then) = _$FreezedUserCopyWithImpl;
@useResult
$Res call({
 CypherId id, String name,@CypherProperty(name: 'emailAddress') String email,@CypherProperty(ignore: true) String password, String? bio
});




}
/// @nodoc
class _$FreezedUserCopyWithImpl<$Res>
    implements $FreezedUserCopyWith<$Res> {
  _$FreezedUserCopyWithImpl(this._self, this._then);

  final FreezedUser _self;
  final $Res Function(FreezedUser) _then;

/// Create a copy of FreezedUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? password = null,Object? bio = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CypherId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FreezedUser].
extension FreezedUserPatterns on FreezedUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreezedUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreezedUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreezedUser value)  $default,){
final _that = this;
switch (_that) {
case _FreezedUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreezedUser value)?  $default,){
final _that = this;
switch (_that) {
case _FreezedUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CypherId id,  String name, @CypherProperty(name: 'emailAddress')  String email, @CypherProperty(ignore: true)  String password,  String? bio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreezedUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.password,_that.bio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CypherId id,  String name, @CypherProperty(name: 'emailAddress')  String email, @CypherProperty(ignore: true)  String password,  String? bio)  $default,) {final _that = this;
switch (_that) {
case _FreezedUser():
return $default(_that.id,_that.name,_that.email,_that.password,_that.bio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CypherId id,  String name, @CypherProperty(name: 'emailAddress')  String email, @CypherProperty(ignore: true)  String password,  String? bio)?  $default,) {final _that = this;
switch (_that) {
case _FreezedUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.password,_that.bio);case _:
  return null;

}
}

}

/// @nodoc


class _FreezedUser implements FreezedUser {
  const _FreezedUser({required this.id, required this.name, @CypherProperty(name: 'emailAddress') required this.email, @CypherProperty(ignore: true) required this.password, this.bio});
  

@override final  CypherId id;
@override final  String name;
@override@CypherProperty(name: 'emailAddress') final  String email;
@override@CypherProperty(ignore: true) final  String password;
@override final  String? bio;

/// Create a copy of FreezedUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreezedUserCopyWith<_FreezedUser> get copyWith => __$FreezedUserCopyWithImpl<_FreezedUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreezedUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.bio, bio) || other.bio == bio));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,password,bio);

@override
String toString() {
  return 'FreezedUser(id: $id, name: $name, email: $email, password: $password, bio: $bio)';
}


}

/// @nodoc
abstract mixin class _$FreezedUserCopyWith<$Res> implements $FreezedUserCopyWith<$Res> {
  factory _$FreezedUserCopyWith(_FreezedUser value, $Res Function(_FreezedUser) _then) = __$FreezedUserCopyWithImpl;
@override @useResult
$Res call({
 CypherId id, String name,@CypherProperty(name: 'emailAddress') String email,@CypherProperty(ignore: true) String password, String? bio
});




}
/// @nodoc
class __$FreezedUserCopyWithImpl<$Res>
    implements _$FreezedUserCopyWith<$Res> {
  __$FreezedUserCopyWithImpl(this._self, this._then);

  final _FreezedUser _self;
  final $Res Function(_FreezedUser) _then;

/// Create a copy of FreezedUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? password = null,Object? bio = freezed,}) {
  return _then(_FreezedUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CypherId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
