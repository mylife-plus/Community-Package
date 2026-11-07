// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedbackQuery {

 FeedbackSort get sort;/// Empty means every type.
 Set<FeedbackType> get types;/// Empty means any status, including none.
 Set<FeedbackStatus> get statuses;/// Trimmed. Empty means no search.
 String get search;
/// Create a copy of FeedbackQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackQueryCopyWith<FeedbackQuery> get copyWith => _$FeedbackQueryCopyWithImpl<FeedbackQuery>(this as FeedbackQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedbackQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackQuery&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&const DeepCollectionEquality().equals(other.types, _this.types)&&const DeepCollectionEquality().equals(other.statuses, _this.statuses)&&(identical(other.search, _this.search) || other.search == _this.search));
}


@override
int get hashCode {
  final _this = this as FeedbackQuery;
  return Object.hash(runtimeType,_this.sort,const DeepCollectionEquality().hash(_this.types),const DeepCollectionEquality().hash(_this.statuses),_this.search);
}

@override
String toString() {
  final _this = this as FeedbackQuery;
  return 'FeedbackQuery(sort: ${_this.sort}, types: ${_this.types}, statuses: ${_this.statuses}, search: ${_this.search})';
}


}

/// @nodoc
abstract mixin class $FeedbackQueryCopyWith<$Res>  {
  factory $FeedbackQueryCopyWith(FeedbackQuery value, $Res Function(FeedbackQuery) _then) = _$FeedbackQueryCopyWithImpl;
@useResult
$Res call({
 FeedbackSort sort, Set<FeedbackType> types, Set<FeedbackStatus> statuses, String search
});




}
/// @nodoc
class _$FeedbackQueryCopyWithImpl<$Res>
    implements $FeedbackQueryCopyWith<$Res> {
  _$FeedbackQueryCopyWithImpl(this._self, this._then);

  final FeedbackQuery _self;
  final $Res Function(FeedbackQuery) _then;

/// Create a copy of FeedbackQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sort = null,Object? types = null,Object? statuses = null,Object? search = null,}) {
  return _then(FeedbackQuery(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as FeedbackSort,types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as Set<FeedbackType>,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as Set<FeedbackStatus>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackQuery].
extension FeedbackQueryPatterns on FeedbackQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackQuery value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackQuery value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FeedbackSort sort,  Set<FeedbackType> types,  Set<FeedbackStatus> statuses,  String search)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackQuery() when $default != null:
return $default(_that.sort,_that.types,_that.statuses,_that.search);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FeedbackSort sort,  Set<FeedbackType> types,  Set<FeedbackStatus> statuses,  String search)  $default,) {final _that = this;
switch (_that) {
case _FeedbackQuery():
return $default(_that.sort,_that.types,_that.statuses,_that.search);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FeedbackSort sort,  Set<FeedbackType> types,  Set<FeedbackStatus> statuses,  String search)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackQuery() when $default != null:
return $default(_that.sort,_that.types,_that.statuses,_that.search);case _:
  return null;

}
}

}

/// @nodoc


class _FeedbackQuery extends FeedbackQuery {
  const _FeedbackQuery({this.sort = FeedbackSort.newest,  Set<FeedbackType> types = const <FeedbackType>{},  Set<FeedbackStatus> statuses = const <FeedbackStatus>{}, this.search = ''}): _types = types,_statuses = statuses,super._();
  

@override@JsonKey() final  FeedbackSort sort;
/// Empty means every type.
 final  Set<FeedbackType> _types;
/// Empty means every type.
@override@JsonKey() Set<FeedbackType> get types {
  if (_types is EqualUnmodifiableSetView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_types);
}

/// Empty means any status, including none.
 final  Set<FeedbackStatus> _statuses;
/// Empty means any status, including none.
@override@JsonKey() Set<FeedbackStatus> get statuses {
  if (_statuses is EqualUnmodifiableSetView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_statuses);
}

/// Trimmed. Empty means no search.
@override@JsonKey() final  String search;

/// Create a copy of FeedbackQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackQueryCopyWith<_FeedbackQuery> get copyWith => __$FeedbackQueryCopyWithImpl<_FeedbackQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackQuery&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other.types, _types)&&const DeepCollectionEquality().equals(other.statuses, _statuses)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sort,const DeepCollectionEquality().hash(_types),const DeepCollectionEquality().hash(_statuses),search);
}

@override
String toString() {
    return 'FeedbackQuery(sort: $sort, types: $types, statuses: $statuses, search: $search)';
}


}

/// @nodoc
abstract mixin class _$FeedbackQueryCopyWith<$Res> implements $FeedbackQueryCopyWith<$Res> {
  factory _$FeedbackQueryCopyWith(_FeedbackQuery value, $Res Function(_FeedbackQuery) _then) = __$FeedbackQueryCopyWithImpl;
@override @useResult
$Res call({
 FeedbackSort sort, Set<FeedbackType> types, Set<FeedbackStatus> statuses, String search
});




}
/// @nodoc
class __$FeedbackQueryCopyWithImpl<$Res>
    implements _$FeedbackQueryCopyWith<$Res> {
  __$FeedbackQueryCopyWithImpl(this._self, this._then);

  final _FeedbackQuery _self;
  final $Res Function(_FeedbackQuery) _then;

/// Create a copy of FeedbackQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sort = null,Object? types = null,Object? statuses = null,Object? search = null,}) {
  return _then(_FeedbackQuery(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as FeedbackSort,types: null == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as Set<FeedbackType>,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as Set<FeedbackStatus>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
