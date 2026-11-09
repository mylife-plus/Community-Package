// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedbackComment _$FeedbackCommentFromJson(Map<String, dynamic> json) =>
    _FeedbackComment(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      text: json['text'] as String,
      lang: json['lang'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      edited: json['edited'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => FeedbackComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FeedbackComment>[],
    );

Map<String, dynamic> _$FeedbackCommentToJson(_FeedbackComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': instance.parentId,
      'text': instance.text,
      'lang': instance.lang,
      'isAdmin': instance.isAdmin,
      'isMine': instance.isMine,
      'deleted': instance.deleted,
      'edited': instance.edited,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'replyCount': instance.replyCount,
      'replies': instance.replies.map((e) => e.toJson()).toList(),
    };

_CommentPage _$CommentPageFromJson(Map<String, dynamic> json) => _CommentPage(
  items:
      (json['items'] as List<dynamic>)
          .map((e) => FeedbackComment.fromJson(e as Map<String, dynamic>))
          .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$CommentPageToJson(_CommentPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
