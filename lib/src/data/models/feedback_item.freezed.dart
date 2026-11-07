// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedbackItem {

/// Per-app number, shown as #21.
 int get number; FeedbackType get type; String get text;/// The author's app language.
 String get lang;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) FeedbackStatus? get status; int? get costCents; String? get githubUrl;/// Problems only, for example `Inventory > Sell Item > Add Item`.
 String? get screenPath;/// Problems only: steps to reproduce.
 List<String>? get steps;/// Problems only: what went wrong, if the author said. [text] then
/// starts with it, followed by the steps.
 String? get description; String? get osVersion; String? get appVersion; String? get deviceModel; int get reactionCount; int get commentCount;/// The current user reacted with a heart.
 bool get reacted;/// The current user wrote it.
 bool get isMine; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of FeedbackItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackItemCopyWith<FeedbackItem> get copyWith => _$FeedbackItemCopyWithImpl<FeedbackItem>(this as FeedbackItem, _$identity);

  /// Serializes this FeedbackItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FeedbackItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackItem&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.lang, _this.lang) || other.lang == _this.lang)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.costCents, _this.costCents) || other.costCents == _this.costCents)&&(identical(other.githubUrl, _this.githubUrl) || other.githubUrl == _this.githubUrl)&&(identical(other.screenPath, _this.screenPath) || other.screenPath == _this.screenPath)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.osVersion, _this.osVersion) || other.osVersion == _this.osVersion)&&(identical(other.appVersion, _this.appVersion) || other.appVersion == _this.appVersion)&&(identical(other.deviceModel, _this.deviceModel) || other.deviceModel == _this.deviceModel)&&(identical(other.reactionCount, _this.reactionCount) || other.reactionCount == _this.reactionCount)&&(identical(other.commentCount, _this.commentCount) || other.commentCount == _this.commentCount)&&(identical(other.reacted, _this.reacted) || other.reacted == _this.reacted)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FeedbackItem;
  return Object.hashAll([runtimeType,_this.number,_this.type,_this.text,_this.lang,_this.status,_this.costCents,_this.githubUrl,_this.screenPath,const DeepCollectionEquality().hash(_this.steps),_this.description,_this.osVersion,_this.appVersion,_this.deviceModel,_this.reactionCount,_this.commentCount,_this.reacted,_this.isMine,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as FeedbackItem;
  return 'FeedbackItem(number: ${_this.number}, type: ${_this.type}, text: ${_this.text}, lang: ${_this.lang}, status: ${_this.status}, costCents: ${_this.costCents}, githubUrl: ${_this.githubUrl}, screenPath: ${_this.screenPath}, steps: ${_this.steps}, description: ${_this.description}, osVersion: ${_this.osVersion}, appVersion: ${_this.appVersion}, deviceModel: ${_this.deviceModel}, reactionCount: ${_this.reactionCount}, commentCount: ${_this.commentCount}, reacted: ${_this.reacted}, isMine: ${_this.isMine}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $FeedbackItemCopyWith<$Res>  {
  factory $FeedbackItemCopyWith(FeedbackItem value, $Res Function(FeedbackItem) _then) = _$FeedbackItemCopyWithImpl;
@useResult
$Res call({
 int number, FeedbackType type, String text, String lang,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) FeedbackStatus? status, int? costCents, String? githubUrl, String? screenPath, List<String>? steps, String? description, String? osVersion, String? appVersion, String? deviceModel, int reactionCount, int commentCount, bool reacted, bool isMine, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$FeedbackItemCopyWithImpl<$Res>
    implements $FeedbackItemCopyWith<$Res> {
  _$FeedbackItemCopyWithImpl(this._self, this._then);

  final FeedbackItem _self;
  final $Res Function(FeedbackItem) _then;

/// Create a copy of FeedbackItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? type = null,Object? text = null,Object? lang = null,Object? status = freezed,Object? costCents = freezed,Object? githubUrl = freezed,Object? screenPath = freezed,Object? steps = freezed,Object? description = freezed,Object? osVersion = freezed,Object? appVersion = freezed,Object? deviceModel = freezed,Object? reactionCount = null,Object? commentCount = null,Object? reacted = null,Object? isMine = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(FeedbackItem(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FeedbackType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeedbackStatus?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,githubUrl: freezed == githubUrl ? _self.githubUrl : githubUrl // ignore: cast_nullable_to_non_nullable
as String?,screenPath: freezed == screenPath ? _self.screenPath : screenPath // ignore: cast_nullable_to_non_nullable
as String?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,deviceModel: freezed == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String?,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,reacted: null == reacted ? _self.reacted : reacted // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackItem].
extension FeedbackItemPatterns on FeedbackItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackItem value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackItem value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  FeedbackType type,  String text,  String lang, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  FeedbackStatus? status,  int? costCents,  String? githubUrl,  String? screenPath,  List<String>? steps,  String? description,  String? osVersion,  String? appVersion,  String? deviceModel,  int reactionCount,  int commentCount,  bool reacted,  bool isMine,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackItem() when $default != null:
return $default(_that.number,_that.type,_that.text,_that.lang,_that.status,_that.costCents,_that.githubUrl,_that.screenPath,_that.steps,_that.description,_that.osVersion,_that.appVersion,_that.deviceModel,_that.reactionCount,_that.commentCount,_that.reacted,_that.isMine,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  FeedbackType type,  String text,  String lang, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  FeedbackStatus? status,  int? costCents,  String? githubUrl,  String? screenPath,  List<String>? steps,  String? description,  String? osVersion,  String? appVersion,  String? deviceModel,  int reactionCount,  int commentCount,  bool reacted,  bool isMine,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FeedbackItem():
return $default(_that.number,_that.type,_that.text,_that.lang,_that.status,_that.costCents,_that.githubUrl,_that.screenPath,_that.steps,_that.description,_that.osVersion,_that.appVersion,_that.deviceModel,_that.reactionCount,_that.commentCount,_that.reacted,_that.isMine,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  FeedbackType type,  String text,  String lang, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  FeedbackStatus? status,  int? costCents,  String? githubUrl,  String? screenPath,  List<String>? steps,  String? description,  String? osVersion,  String? appVersion,  String? deviceModel,  int reactionCount,  int commentCount,  bool reacted,  bool isMine,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackItem() when $default != null:
return $default(_that.number,_that.type,_that.text,_that.lang,_that.status,_that.costCents,_that.githubUrl,_that.screenPath,_that.steps,_that.description,_that.osVersion,_that.appVersion,_that.deviceModel,_that.reactionCount,_that.commentCount,_that.reacted,_that.isMine,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedbackItem implements FeedbackItem {
  const _FeedbackItem({required this.number, required this.type, required this.text, required this.lang, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.status, this.costCents, this.githubUrl, this.screenPath,  List<String>? steps, this.description, this.osVersion, this.appVersion, this.deviceModel, this.reactionCount = 0, this.commentCount = 0, this.reacted = false, this.isMine = false, required this.createdAt, required this.updatedAt}): _steps = steps;
  factory _FeedbackItem.fromJson(Map<String, dynamic> json) => _$FeedbackItemFromJson(json);

/// Per-app number, shown as #21.
@override final  int number;
@override final  FeedbackType type;
@override final  String text;
/// The author's app language.
@override final  String lang;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  FeedbackStatus? status;
@override final  int? costCents;
@override final  String? githubUrl;
/// Problems only, for example `Inventory > Sell Item > Add Item`.
@override final  String? screenPath;
/// Problems only: steps to reproduce.
 final  List<String>? _steps;
/// Problems only: steps to reproduce.
@override List<String>? get steps {
  final value = _steps;
  if (value == null) return null;
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Problems only: what went wrong, if the author said. [text] then
/// starts with it, followed by the steps.
@override final  String? description;
@override final  String? osVersion;
@override final  String? appVersion;
@override final  String? deviceModel;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
/// The current user reacted with a heart.
@override@JsonKey() final  bool reacted;
/// The current user wrote it.
@override@JsonKey() final  bool isMine;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of FeedbackItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackItemCopyWith<_FeedbackItem> get copyWith => __$FeedbackItemCopyWithImpl<_FeedbackItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedbackItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackItem&&(identical(other.number, number) || other.number == number)&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.status, status) || other.status == status)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.githubUrl, githubUrl) || other.githubUrl == githubUrl)&&(identical(other.screenPath, screenPath) || other.screenPath == screenPath)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.description, description) || other.description == description)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.deviceModel, deviceModel) || other.deviceModel == deviceModel)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.reacted, reacted) || other.reacted == reacted)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,number,type,text,lang,status,costCents,githubUrl,screenPath,const DeepCollectionEquality().hash(_steps),description,osVersion,appVersion,deviceModel,reactionCount,commentCount,reacted,isMine,createdAt,updatedAt]);
}

@override
String toString() {
    return 'FeedbackItem(number: $number, type: $type, text: $text, lang: $lang, status: $status, costCents: $costCents, githubUrl: $githubUrl, screenPath: $screenPath, steps: $steps, description: $description, osVersion: $osVersion, appVersion: $appVersion, deviceModel: $deviceModel, reactionCount: $reactionCount, commentCount: $commentCount, reacted: $reacted, isMine: $isMine, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FeedbackItemCopyWith<$Res> implements $FeedbackItemCopyWith<$Res> {
  factory _$FeedbackItemCopyWith(_FeedbackItem value, $Res Function(_FeedbackItem) _then) = __$FeedbackItemCopyWithImpl;
@override @useResult
$Res call({
 int number, FeedbackType type, String text, String lang,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) FeedbackStatus? status, int? costCents, String? githubUrl, String? screenPath, List<String>? steps, String? description, String? osVersion, String? appVersion, String? deviceModel, int reactionCount, int commentCount, bool reacted, bool isMine, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$FeedbackItemCopyWithImpl<$Res>
    implements _$FeedbackItemCopyWith<$Res> {
  __$FeedbackItemCopyWithImpl(this._self, this._then);

  final _FeedbackItem _self;
  final $Res Function(_FeedbackItem) _then;

/// Create a copy of FeedbackItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? type = null,Object? text = null,Object? lang = null,Object? status = freezed,Object? costCents = freezed,Object? githubUrl = freezed,Object? screenPath = freezed,Object? steps = freezed,Object? description = freezed,Object? osVersion = freezed,Object? appVersion = freezed,Object? deviceModel = freezed,Object? reactionCount = null,Object? commentCount = null,Object? reacted = null,Object? isMine = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_FeedbackItem(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FeedbackType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FeedbackStatus?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,githubUrl: freezed == githubUrl ? _self.githubUrl : githubUrl // ignore: cast_nullable_to_non_nullable
as String?,screenPath: freezed == screenPath ? _self.screenPath : screenPath // ignore: cast_nullable_to_non_nullable
as String?,steps: freezed == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,deviceModel: freezed == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String?,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,reacted: null == reacted ? _self.reacted : reacted // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$FeedbackPage {

 List<FeedbackItem> get items;/// Pass back as `?cursor=` for the next page. Null on the last page.
 String? get nextCursor;
/// Create a copy of FeedbackPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackPageCopyWith<FeedbackPage> get copyWith => _$FeedbackPageCopyWithImpl<FeedbackPage>(this as FeedbackPage, _$identity);

  /// Serializes this FeedbackPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FeedbackPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FeedbackPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor);
}

@override
String toString() {
  final _this = this as FeedbackPage;
  return 'FeedbackPage(items: ${_this.items}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $FeedbackPageCopyWith<$Res>  {
  factory $FeedbackPageCopyWith(FeedbackPage value, $Res Function(FeedbackPage) _then) = _$FeedbackPageCopyWithImpl;
@useResult
$Res call({
 List<FeedbackItem> items, String? nextCursor
});




}
/// @nodoc
class _$FeedbackPageCopyWithImpl<$Res>
    implements $FeedbackPageCopyWith<$Res> {
  _$FeedbackPageCopyWithImpl(this._self, this._then);

  final FeedbackPage _self;
  final $Res Function(FeedbackPage) _then;

/// Create a copy of FeedbackPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(FeedbackPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FeedbackItem>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackPage].
extension FeedbackPagePatterns on FeedbackPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackPage value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackPage value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FeedbackItem> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FeedbackItem> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _FeedbackPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FeedbackItem> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedbackPage implements FeedbackPage {
  const _FeedbackPage({required  List<FeedbackItem> items, this.nextCursor}): _items = items;
  factory _FeedbackPage.fromJson(Map<String, dynamic> json) => _$FeedbackPageFromJson(json);

 final  List<FeedbackItem> _items;
@override List<FeedbackItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Pass back as `?cursor=` for the next page. Null on the last page.
@override final  String? nextCursor;

/// Create a copy of FeedbackPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackPageCopyWith<_FeedbackPage> get copyWith => __$FeedbackPageCopyWithImpl<_FeedbackPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedbackPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);
}

@override
String toString() {
    return 'FeedbackPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$FeedbackPageCopyWith<$Res> implements $FeedbackPageCopyWith<$Res> {
  factory _$FeedbackPageCopyWith(_FeedbackPage value, $Res Function(_FeedbackPage) _then) = __$FeedbackPageCopyWithImpl;
@override @useResult
$Res call({
 List<FeedbackItem> items, String? nextCursor
});




}
/// @nodoc
class __$FeedbackPageCopyWithImpl<$Res>
    implements _$FeedbackPageCopyWith<$Res> {
  __$FeedbackPageCopyWithImpl(this._self, this._then);

  final _FeedbackPage _self;
  final $Res Function(_FeedbackPage) _then;

/// Create a copy of FeedbackPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_FeedbackPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FeedbackItem>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
