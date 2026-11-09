import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_comment.freezed.dart';
part 'feedback_comment.g.dart';

/// A comment on a feedback, or a reply to one. Replies are one level deep:
/// only top-level comments have [replies].
@freezed
abstract class FeedbackComment with _$FeedbackComment {
  const FeedbackComment._();

  const factory FeedbackComment({
    required int id,

    /// The top-level comment this replies to. Null for a top-level comment.
    int? parentId,

    /// Empty when [deleted].
    required String text,

    /// The writer's app language.
    required String lang,

    /// Written by the admin. Shown with an "Admin" label from S10.
    @Default(false) bool isAdmin,

    /// The current user wrote it, so they can edit and delete it.
    @Default(false) bool isMine,

    /// The writer deleted it while it had replies: it stays as a
    /// placeholder above them.
    @Default(false) bool deleted,

    /// Changed after it was posted.
    @Default(false) bool edited,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int replyCount,

    /// Oldest first.
    @Default(<FeedbackComment>[]) List<FeedbackComment> replies,
  }) = _FeedbackComment;

  factory FeedbackComment.fromJson(Map<String, dynamic> json) => _$FeedbackCommentFromJson(json);

  bool get isReply => parentId != null;
}

/// A page of top-level comments, or every page loaded so far.
@freezed
abstract class CommentPage with _$CommentPage {
  const factory CommentPage({
    required List<FeedbackComment> items,

    /// Pass back as `?cursor=` for the next page. Null on the last page.
    String? nextCursor,
  }) = _CommentPage;

  factory CommentPage.fromJson(Map<String, dynamic> json) => _$CommentPageFromJson(json);
}
