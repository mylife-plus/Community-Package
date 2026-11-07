import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_item.freezed.dart';
part 'feedback_item.g.dart';

enum FeedbackType { improvement, problem, idea }

enum FeedbackStatus {
  planned,
  @JsonValue('in_progress')
  inProgress,
  done,
}

/// One feedback post, as the list and detail screens see it.
@freezed
abstract class FeedbackItem with _$FeedbackItem {
  const factory FeedbackItem({
    /// Per-app number, shown as #21.
    required int number,
    required FeedbackType type,
    required String text,

    /// The author's app language.
    required String lang,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) FeedbackStatus? status,
    int? costCents,
    String? githubUrl,

    /// Problems only, for example `Inventory > Sell Item > Add Item`.
    String? screenPath,

    /// Problems only: steps to reproduce.
    List<String>? steps,

    /// Problems only: what went wrong, if the author said. [text] then
    /// starts with it, followed by the steps.
    String? description,
    String? osVersion,
    String? appVersion,
    String? deviceModel,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,

    /// The current user reacted with a heart.
    @Default(false) bool reacted,

    /// The current user wrote it.
    @Default(false) bool isMine,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FeedbackItem;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => _$FeedbackItemFromJson(json);
}

/// A page of feedback, or every page loaded so far.
@freezed
abstract class FeedbackPage with _$FeedbackPage {
  const factory FeedbackPage({
    required List<FeedbackItem> items,

    /// Pass back as `?cursor=` for the next page. Null on the last page.
    String? nextCursor,
  }) = _FeedbackPage;

  factory FeedbackPage.fromJson(Map<String, dynamic> json) => _$FeedbackPageFromJson(json);
}
