// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentQuery {

 CommentSort get sort;/// Empty means every comment.
 Set<CommentFilter> get filters;/// Trimmed. Empty means no search.
 String get search;
/// Create a copy of CommentQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentQueryCopyWith<CommentQuery> get copyWith => _$CommentQueryCopyWithImpl<CommentQuery>(this as CommentQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CommentQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentQuery&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&const DeepCollectionEquality().equals(other.filters, _this.filters)&&(identical(other.search, _this.search) || other.search == _this.search));
}


@override
int get hashCode {
  final _this = this as CommentQuery;
  return Object.hash(runtimeType,_this.sort,const DeepCollectionEquality().hash(_this.filters),_this.search);
}

@override
String toString() {
  final _this = this as CommentQuery;
  return 'CommentQuery(sort: ${_this.sort}, filters: ${_this.filters}, search: ${_this.search})';
}


}

/// @nodoc
abstract mixin class $CommentQueryCopyWith<$Res>  {
  factory $CommentQueryCopyWith(CommentQuery value, $Res Function(CommentQuery) _then) = _$CommentQueryCopyWithImpl;
@useResult
$Res call({
 CommentSort sort, Set<CommentFilter> filters, String search
});




}
/// @nodoc
class _$CommentQueryCopyWithImpl<$Res>
    implements $CommentQueryCopyWith<$Res> {
  _$CommentQueryCopyWithImpl(this._self, this._then);

  final CommentQuery _self;
  final $Res Function(CommentQuery) _then;

/// Create a copy of CommentQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sort = null,Object? filters = null,Object? search = null,}) {
  return _then(CommentQuery(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as CommentSort,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as Set<CommentFilter>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentQuery].
extension CommentQueryPatterns on CommentQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentQuery value)  $default,){
final _that = this;
switch (_that) {
case _CommentQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentQuery value)?  $default,){
final _that = this;
switch (_that) {
case _CommentQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CommentSort sort,  Set<CommentFilter> filters,  String search)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentQuery() when $default != null:
return $default(_that.sort,_that.filters,_that.search);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CommentSort sort,  Set<CommentFilter> filters,  String search)  $default,) {final _that = this;
switch (_that) {
case _CommentQuery():
return $default(_that.sort,_that.filters,_that.search);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CommentSort sort,  Set<CommentFilter> filters,  String search)?  $default,) {final _that = this;
switch (_that) {
case _CommentQuery() when $default != null:
return $default(_that.sort,_that.filters,_that.search);case _:
  return null;

}
}

}

/// @nodoc


class _CommentQuery extends CommentQuery {
  const _CommentQuery({this.sort = CommentSort.newest,  Set<CommentFilter> filters = const <CommentFilter>{}, this.search = ''}): _filters = filters,super._();
  

@override@JsonKey() final  CommentSort sort;
/// Empty means every comment.
 final  Set<CommentFilter> _filters;
/// Empty means every comment.
@override@JsonKey() Set<CommentFilter> get filters {
  if (_filters is EqualUnmodifiableSetView) return _filters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_filters);
}

/// Trimmed. Empty means no search.
@override@JsonKey() final  String search;

/// Create a copy of CommentQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentQueryCopyWith<_CommentQuery> get copyWith => __$CommentQueryCopyWithImpl<_CommentQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentQuery&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other.filters, _filters)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sort,const DeepCollectionEquality().hash(_filters),search);
}

@override
String toString() {
    return 'CommentQuery(sort: $sort, filters: $filters, search: $search)';
}


}

/// @nodoc
abstract mixin class _$CommentQueryCopyWith<$Res> implements $CommentQueryCopyWith<$Res> {
  factory _$CommentQueryCopyWith(_CommentQuery value, $Res Function(_CommentQuery) _then) = __$CommentQueryCopyWithImpl;
@override @useResult
$Res call({
 CommentSort sort, Set<CommentFilter> filters, String search
});




}
/// @nodoc
class __$CommentQueryCopyWithImpl<$Res>
    implements _$CommentQueryCopyWith<$Res> {
  __$CommentQueryCopyWithImpl(this._self, this._then);

  final _CommentQuery _self;
  final $Res Function(_CommentQuery) _then;

/// Create a copy of CommentQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sort = null,Object? filters = null,Object? search = null,}) {
  return _then(_CommentQuery(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as CommentSort,filters: null == filters ? _self._filters : filters // ignore: cast_nullable_to_non_nullable
as Set<CommentFilter>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
