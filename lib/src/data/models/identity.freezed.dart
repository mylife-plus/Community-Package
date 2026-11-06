// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Identity {

/// Exists only after the user agreed to the privacy notice.
 String? get anonId;/// Agreed to the community rules. Asked once, before the first post.
 bool get rulesAgreed;
/// Create a copy of Identity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdentityCopyWith<Identity> get copyWith => _$IdentityCopyWithImpl<Identity>(this as Identity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Identity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Identity&&(identical(other.anonId, _this.anonId) || other.anonId == _this.anonId)&&(identical(other.rulesAgreed, _this.rulesAgreed) || other.rulesAgreed == _this.rulesAgreed));
}


@override
int get hashCode {
  final _this = this as Identity;
  return Object.hash(runtimeType,_this.anonId,_this.rulesAgreed);
}

@override
String toString() {
  final _this = this as Identity;
  return 'Identity(anonId: ${_this.anonId}, rulesAgreed: ${_this.rulesAgreed})';
}


}

/// @nodoc
abstract mixin class $IdentityCopyWith<$Res>  {
  factory $IdentityCopyWith(Identity value, $Res Function(Identity) _then) = _$IdentityCopyWithImpl;
@useResult
$Res call({
 String? anonId, bool rulesAgreed
});




}
/// @nodoc
class _$IdentityCopyWithImpl<$Res>
    implements $IdentityCopyWith<$Res> {
  _$IdentityCopyWithImpl(this._self, this._then);

  final Identity _self;
  final $Res Function(Identity) _then;

/// Create a copy of Identity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? anonId = freezed,Object? rulesAgreed = null,}) {
  return _then(Identity(
anonId: freezed == anonId ? _self.anonId : anonId // ignore: cast_nullable_to_non_nullable
as String?,rulesAgreed: null == rulesAgreed ? _self.rulesAgreed : rulesAgreed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Identity].
extension IdentityPatterns on Identity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Identity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Identity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Identity value)  $default,){
final _that = this;
switch (_that) {
case _Identity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Identity value)?  $default,){
final _that = this;
switch (_that) {
case _Identity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? anonId,  bool rulesAgreed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Identity() when $default != null:
return $default(_that.anonId,_that.rulesAgreed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? anonId,  bool rulesAgreed)  $default,) {final _that = this;
switch (_that) {
case _Identity():
return $default(_that.anonId,_that.rulesAgreed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? anonId,  bool rulesAgreed)?  $default,) {final _that = this;
switch (_that) {
case _Identity() when $default != null:
return $default(_that.anonId,_that.rulesAgreed);case _:
  return null;

}
}

}

/// @nodoc


class _Identity extends Identity {
  const _Identity({this.anonId, this.rulesAgreed = false}): super._();
  

/// Exists only after the user agreed to the privacy notice.
@override final  String? anonId;
/// Agreed to the community rules. Asked once, before the first post.
@override@JsonKey() final  bool rulesAgreed;

/// Create a copy of Identity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IdentityCopyWith<_Identity> get copyWith => __$IdentityCopyWithImpl<_Identity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Identity&&(identical(other.anonId, anonId) || other.anonId == anonId)&&(identical(other.rulesAgreed, rulesAgreed) || other.rulesAgreed == rulesAgreed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,anonId,rulesAgreed);
}

@override
String toString() {
    return 'Identity(anonId: $anonId, rulesAgreed: $rulesAgreed)';
}


}

/// @nodoc
abstract mixin class _$IdentityCopyWith<$Res> implements $IdentityCopyWith<$Res> {
  factory _$IdentityCopyWith(_Identity value, $Res Function(_Identity) _then) = __$IdentityCopyWithImpl;
@override @useResult
$Res call({
 String? anonId, bool rulesAgreed
});




}
/// @nodoc
class __$IdentityCopyWithImpl<$Res>
    implements _$IdentityCopyWith<$Res> {
  __$IdentityCopyWithImpl(this._self, this._then);

  final _Identity _self;
  final $Res Function(_Identity) _then;

/// Create a copy of Identity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? anonId = freezed,Object? rulesAgreed = null,}) {
  return _then(_Identity(
anonId: freezed == anonId ? _self.anonId : anonId // ignore: cast_nullable_to_non_nullable
as String?,rulesAgreed: null == rulesAgreed ? _self.rulesAgreed : rulesAgreed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
