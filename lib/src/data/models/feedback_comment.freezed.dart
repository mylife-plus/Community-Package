// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedbackComment {

 int get id;/// The top-level comment this replies to. Null for a top-level comment.
 int? get parentId;/// Empty when [deleted].
 String get text;/// The writer's app language.
 String get lang;/// Written by the admin. Shown with an "Admin" label from S10.
 bool get isAdmin;/// The current user wrote it, so they can edit and delete it.
 bool get isMine;/// The writer deleted it while it had replies: it stays as a
/// placeholder above them.
 bool get deleted;/// Changed after it was posted.
 bool get edited; DateTime get createdAt; DateTime get updatedAt; int get replyCount;/// Oldest first.
 List<FeedbackComment> get replies;
/// Create a copy of FeedbackComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackCommentCopyWith<FeedbackComment> get copyWith => _$FeedbackCommentCopyWithImpl<FeedbackComment>(this as FeedbackComment, _$identity);

  /// Serializes this FeedbackComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FeedbackComment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackComment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.lang, _this.lang) || other.lang == _this.lang)&&(identical(other.isAdmin, _this.isAdmin) || other.isAdmin == _this.isAdmin)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.deleted, _this.deleted) || other.deleted == _this.deleted)&&(identical(other.edited, _this.edited) || other.edited == _this.edited)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.replyCount, _this.replyCount) || other.replyCount == _this.replyCount)&&const DeepCollectionEquality().equals(other.replies, _this.replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FeedbackComment;
  return Object.hash(runtimeType,_this.id,_this.parentId,_this.text,_this.lang,_this.isAdmin,_this.isMine,_this.deleted,_this.edited,_this.createdAt,_this.updatedAt,_this.replyCount,const DeepCollectionEquality().hash(_this.replies));
}

@override
String toString() {
  final _this = this as FeedbackComment;
  return 'FeedbackComment(id: ${_this.id}, parentId: ${_this.parentId}, text: ${_this.text}, lang: ${_this.lang}, isAdmin: ${_this.isAdmin}, isMine: ${_this.isMine}, deleted: ${_this.deleted}, edited: ${_this.edited}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, replyCount: ${_this.replyCount}, replies: ${_this.replies})';
}


}

/// @nodoc
abstract mixin class $FeedbackCommentCopyWith<$Res>  {
  factory $FeedbackCommentCopyWith(FeedbackComment value, $Res Function(FeedbackComment) _then) = _$FeedbackCommentCopyWithImpl;
@useResult
$Res call({
 int id, int? parentId, String text, String lang, bool isAdmin, bool isMine, bool deleted, bool edited, DateTime createdAt, DateTime updatedAt, int replyCount, List<FeedbackComment> replies
});




}
/// @nodoc
class _$FeedbackCommentCopyWithImpl<$Res>
    implements $FeedbackCommentCopyWith<$Res> {
  _$FeedbackCommentCopyWithImpl(this._self, this._then);

  final FeedbackComment _self;
  final $Res Function(FeedbackComment) _then;

/// Create a copy of FeedbackComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = freezed,Object? text = null,Object? lang = null,Object? isAdmin = null,Object? isMine = null,Object? deleted = null,Object? edited = null,Object? createdAt = null,Object? updatedAt = null,Object? replyCount = null,Object? replies = null,}) {
  return _then(FeedbackComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<FeedbackComment>,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackComment].
extension FeedbackCommentPatterns on FeedbackComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackComment value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackComment value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? parentId,  String text,  String lang,  bool isAdmin,  bool isMine,  bool deleted,  bool edited,  DateTime createdAt,  DateTime updatedAt,  int replyCount,  List<FeedbackComment> replies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackComment() when $default != null:
return $default(_that.id,_that.parentId,_that.text,_that.lang,_that.isAdmin,_that.isMine,_that.deleted,_that.edited,_that.createdAt,_that.updatedAt,_that.replyCount,_that.replies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? parentId,  String text,  String lang,  bool isAdmin,  bool isMine,  bool deleted,  bool edited,  DateTime createdAt,  DateTime updatedAt,  int replyCount,  List<FeedbackComment> replies)  $default,) {final _that = this;
switch (_that) {
case _FeedbackComment():
return $default(_that.id,_that.parentId,_that.text,_that.lang,_that.isAdmin,_that.isMine,_that.deleted,_that.edited,_that.createdAt,_that.updatedAt,_that.replyCount,_that.replies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? parentId,  String text,  String lang,  bool isAdmin,  bool isMine,  bool deleted,  bool edited,  DateTime createdAt,  DateTime updatedAt,  int replyCount,  List<FeedbackComment> replies)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackComment() when $default != null:
return $default(_that.id,_that.parentId,_that.text,_that.lang,_that.isAdmin,_that.isMine,_that.deleted,_that.edited,_that.createdAt,_that.updatedAt,_that.replyCount,_that.replies);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedbackComment extends FeedbackComment {
  const _FeedbackComment({required this.id, this.parentId, required this.text, required this.lang, this.isAdmin = false, this.isMine = false, this.deleted = false, this.edited = false, required this.createdAt, required this.updatedAt, this.replyCount = 0,  List<FeedbackComment> replies = const <FeedbackComment>[]}): _replies = replies,super._();
  factory _FeedbackComment.fromJson(Map<String, dynamic> json) => _$FeedbackCommentFromJson(json);

@override final  int id;
/// The top-level comment this replies to. Null for a top-level comment.
@override final  int? parentId;
/// Empty when [deleted].
@override final  String text;
/// The writer's app language.
@override final  String lang;
/// Written by the admin. Shown with an "Admin" label from S10.
@override@JsonKey() final  bool isAdmin;
/// The current user wrote it, so they can edit and delete it.
@override@JsonKey() final  bool isMine;
/// The writer deleted it while it had replies: it stays as a
/// placeholder above them.
@override@JsonKey() final  bool deleted;
/// Changed after it was posted.
@override@JsonKey() final  bool edited;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  int replyCount;
/// Oldest first.
 final  List<FeedbackComment> _replies;
/// Oldest first.
@override@JsonKey() List<FeedbackComment> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}


/// Create a copy of FeedbackComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackCommentCopyWith<_FeedbackComment> get copyWith => __$FeedbackCommentCopyWithImpl<_FeedbackComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedbackCommentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackComment&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.text, text) || other.text == text)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.deleted, deleted) || other.deleted == deleted)&&(identical(other.edited, edited) || other.edited == edited)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&const DeepCollectionEquality().equals(other.replies, _replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,parentId,text,lang,isAdmin,isMine,deleted,edited,createdAt,updatedAt,replyCount,const DeepCollectionEquality().hash(_replies));
}

@override
String toString() {
    return 'FeedbackComment(id: $id, parentId: $parentId, text: $text, lang: $lang, isAdmin: $isAdmin, isMine: $isMine, deleted: $deleted, edited: $edited, createdAt: $createdAt, updatedAt: $updatedAt, replyCount: $replyCount, replies: $replies)';
}


}

/// @nodoc
abstract mixin class _$FeedbackCommentCopyWith<$Res> implements $FeedbackCommentCopyWith<$Res> {
  factory _$FeedbackCommentCopyWith(_FeedbackComment value, $Res Function(_FeedbackComment) _then) = __$FeedbackCommentCopyWithImpl;
@override @useResult
$Res call({
 int id, int? parentId, String text, String lang, bool isAdmin, bool isMine, bool deleted, bool edited, DateTime createdAt, DateTime updatedAt, int replyCount, List<FeedbackComment> replies
});




}
/// @nodoc
class __$FeedbackCommentCopyWithImpl<$Res>
    implements _$FeedbackCommentCopyWith<$Res> {
  __$FeedbackCommentCopyWithImpl(this._self, this._then);

  final _FeedbackComment _self;
  final $Res Function(_FeedbackComment) _then;

/// Create a copy of FeedbackComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = freezed,Object? text = null,Object? lang = null,Object? isAdmin = null,Object? isMine = null,Object? deleted = null,Object? edited = null,Object? createdAt = null,Object? updatedAt = null,Object? replyCount = null,Object? replies = null,}) {
  return _then(_FeedbackComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<FeedbackComment>,
  ));
}


}


/// @nodoc
mixin _$CommentPage {

 List<FeedbackComment> get items;/// Pass back as `?cursor=` for the next page. Null on the last page.
 String? get nextCursor;
/// Create a copy of CommentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentPageCopyWith<CommentPage> get copyWith => _$CommentPageCopyWithImpl<CommentPage>(this as CommentPage, _$identity);

  /// Serializes this CommentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommentPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommentPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor);
}

@override
String toString() {
  final _this = this as CommentPage;
  return 'CommentPage(items: ${_this.items}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $CommentPageCopyWith<$Res>  {
  factory $CommentPageCopyWith(CommentPage value, $Res Function(CommentPage) _then) = _$CommentPageCopyWithImpl;
@useResult
$Res call({
 List<FeedbackComment> items, String? nextCursor
});




}
/// @nodoc
class _$CommentPageCopyWithImpl<$Res>
    implements $CommentPageCopyWith<$Res> {
  _$CommentPageCopyWithImpl(this._self, this._then);

  final CommentPage _self;
  final $Res Function(CommentPage) _then;

/// Create a copy of CommentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(CommentPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FeedbackComment>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentPage].
extension CommentPagePatterns on CommentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentPage value)  $default,){
final _that = this;
switch (_that) {
case _CommentPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentPage value)?  $default,){
final _that = this;
switch (_that) {
case _CommentPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FeedbackComment> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FeedbackComment> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _CommentPage():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FeedbackComment> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _CommentPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentPage implements CommentPage {
  const _CommentPage({required  List<FeedbackComment> items, this.nextCursor}): _items = items;
  factory _CommentPage.fromJson(Map<String, dynamic> json) => _$CommentPageFromJson(json);

 final  List<FeedbackComment> _items;
@override List<FeedbackComment> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Pass back as `?cursor=` for the next page. Null on the last page.
@override final  String? nextCursor;

/// Create a copy of CommentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentPageCopyWith<_CommentPage> get copyWith => __$CommentPageCopyWithImpl<_CommentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);
}

@override
String toString() {
    return 'CommentPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$CommentPageCopyWith<$Res> implements $CommentPageCopyWith<$Res> {
  factory _$CommentPageCopyWith(_CommentPage value, $Res Function(_CommentPage) _then) = __$CommentPageCopyWithImpl;
@override @useResult
$Res call({
 List<FeedbackComment> items, String? nextCursor
});




}
/// @nodoc
class __$CommentPageCopyWithImpl<$Res>
    implements _$CommentPageCopyWith<$Res> {
  __$CommentPageCopyWithImpl(this._self, this._then);

  final _CommentPage _self;
  final $Res Function(_CommentPage) _then;

/// Create a copy of CommentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_CommentPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FeedbackComment>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
