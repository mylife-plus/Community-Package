import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/refresh_buttons.dart';
import '../../../data/models/feedback_comment.dart';
import 'comment_field.dart';

/// A top-level comment with its replies, in one card (Settings-6 layout,
/// refreshed look): age and text, then a tonal "2 replies" chip that opens
/// and closes the replies with an animation, and at the end of the open
/// thread a "Reply" button that turns into a focused reply field
/// ([replying]). Left empty, the field turns back into the button
/// (Johannes, 11 Nov). The user's own comments have an edit button that
/// opens Edit Comment.
class CommentThread extends StatelessWidget {
  const CommentThread({
    super.key,
    required this.thread,
    required this.open,
    required this.onToggle,
    required this.onEdit,
    required this.replyController,
    required this.replying,
    required this.onReply,
    required this.onLeaveReply,
    required this.sendingReply,
    required this.onSendReply,
    required this.maxLength,
    this.now,
  });

  final FeedbackComment thread;

  /// The replies and the reply field show.
  final bool open;
  final VoidCallback onToggle;

  /// The ✏️ of one of the user's own comments: [thread] or a reply.
  final ValueChanged<FeedbackComment> onEdit;
  final TextEditingController replyController;

  /// The reply field shows instead of the "+".
  final bool replying;

  /// The "+": show the reply field.
  final VoidCallback onReply;

  /// The reply field lost focus; the screen turns it back into the "+" if
  /// it is empty.
  final VoidCallback onLeaveReply;
  final bool sendingReply;
  final VoidCallback onSendReply;
  final int maxLength;

  /// For tests. Defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final card = RefreshColors.card(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: RefreshTokens.cardPadding,
      endIndent: RefreshTokens.cardPadding,
      color: RefreshColors.faintBorder(context),
    );

    return Material(
      color: card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: RefreshColors.faintBorder(context)),
        borderRadius: BorderRadius.circular(RefreshTokens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommentBody(comment: thread, onEdit: onEdit, now: now),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RepliesChip(count: thread.replies.length, open: open, onTap: onToggle),
            ),
          ),
          AnimatedSize(
            duration: RefreshTokens.expandDuration,
            curve: RefreshTokens.expandCurve,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final reply in thread.replies) ...[
                        divider,
                        _CommentBody(comment: reply, onEdit: onEdit, now: now),
                      ],
                      divider,
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: replying
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Focus(
                                  canRequestFocus: false,
                                  skipTraversal: true,
                                  onFocusChange: (focused) {
                                    if (!focused) onLeaveReply();
                                  },
                                  child: CommentField(
                                    controller: replyController,
                                    sending: sendingReply,
                                    onSend: onSendReply,
                                    maxLength: maxLength,
                                    autofocus: true,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: onReply,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                    minimumSize: const Size(64, RefreshTokens.minTarget),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(RefreshTokens.controlRadius),
                                    ),
                                    textStyle: RefreshTokens.body(context, weight: FontWeight.w600),
                                  ),
                                  icon: const Icon(Icons.subdirectory_arrow_right_rounded, size: 20),
                                  label: Text(l.reply),
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Age (with "· edited"), the edit button for the user's own comment, and
/// the text, or "Comment deleted" in its place.
class _CommentBody extends StatelessWidget {
  const _CommentBody({required this.comment, required this.onEdit, required this.now});

  final FeedbackComment comment;
  final ValueChanged<FeedbackComment> onEdit;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final card = RefreshColors.card(context);
    final age = formatAge(l, comment.createdAt, now: now);
    final editable = comment.isMine;

    // The meta row is 48 high, so the edit button gets its full tap area
    // in the card's corner; the text keeps the card's 16 inset.
    return Padding(
      padding: const EdgeInsets.fromLTRB(RefreshTokens.cardPadding, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: RefreshTokens.minTarget,
            child: Row(
              children: [
                // Expanded, so the edit button always ends at the card's
                // edge.
                Expanded(
                  child: Text(
                    comment.edited ? '$age · ${l.edited}' : age,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RefreshTokens.meta(context, on: card),
                  ),
                ),
                if (editable)
                  RefreshIconButton(
                    tooltip: l.editComment,
                    onPressed: () => onEdit(comment),
                    color: RefreshColors.meta(context, on: card),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: RefreshTokens.cardPadding - 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.deleted)
                  Text(
                    l.commentDeleted,
                    style: RefreshTokens.body(
                      context,
                      color: RefreshColors.meta(context, on: card),
                    )?.copyWith(fontStyle: FontStyle.italic),
                  )
                else
                  Text(comment.text, style: RefreshTokens.body(context, color: scheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tonal pill: "2 replies" with a chevron that turns as the replies open
/// and close. Without replies it reads "Reply" and opens the reply field.
/// The pill is 40 high; the 4 above and below take taps too (48).
class _RepliesChip extends StatelessWidget {
  const _RepliesChip({required this.count, required this.open, required this.onTap});

  final int count;
  final bool open;
  final VoidCallback onTap;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = RefreshColors.tonal(context);
    final semantics = open ? l.hideReplies : (count == 0 ? l.reply : l.showReplies(count));
    return Semantics(
      button: true,
      expanded: open,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: (RefreshTokens.minTarget - _height) / 2),
          child: Material(
            color: background,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: EdgeInsets.only(left: 14, right: count == 0 ? 14 : 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count == 0 ? l.reply : l.replyCount(count),
                        style: RefreshTokens.meta(context, color: scheme.onSurface, weight: FontWeight.w600),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: RefreshTokens.expandDuration,
                          curve: RefreshTokens.expandCurve,
                          child: Icon(Icons.expand_more_rounded, size: 20, color: scheme.onSurface),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
