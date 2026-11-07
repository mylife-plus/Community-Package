// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedbackItem _$FeedbackItemFromJson(Map<String, dynamic> json) =>
    _FeedbackItem(
      number: (json['number'] as num).toInt(),
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      text: json['text'] as String,
      lang: json['lang'] as String,
      status: $enumDecodeNullable(
        _$FeedbackStatusEnumMap,
        json['status'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      costCents: (json['costCents'] as num?)?.toInt(),
      githubUrl: json['githubUrl'] as String?,
      screenPath: json['screenPath'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList(),
      description: json['description'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      deviceModel: json['deviceModel'] as String?,
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      reacted: json['reacted'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FeedbackItemToJson(_FeedbackItem instance) =>
    <String, dynamic>{
      'number': instance.number,
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'text': instance.text,
      'lang': instance.lang,
      'status': _$FeedbackStatusEnumMap[instance.status],
      'costCents': instance.costCents,
      'githubUrl': instance.githubUrl,
      'screenPath': instance.screenPath,
      'steps': instance.steps,
      'description': instance.description,
      'osVersion': instance.osVersion,
      'appVersion': instance.appVersion,
      'deviceModel': instance.deviceModel,
      'reactionCount': instance.reactionCount,
      'commentCount': instance.commentCount,
      'reacted': instance.reacted,
      'isMine': instance.isMine,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.improvement: 'improvement',
  FeedbackType.problem: 'problem',
  FeedbackType.idea: 'idea',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.planned: 'planned',
  FeedbackStatus.inProgress: 'in_progress',
  FeedbackStatus.done: 'done',
};

_FeedbackPage _$FeedbackPageFromJson(Map<String, dynamic> json) =>
    _FeedbackPage(
      items:
          (json['items'] as List<dynamic>)
              .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$FeedbackPageToJson(_FeedbackPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
