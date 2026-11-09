import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/emoji_text.dart';
import '../../../data/models/feedback_comment.dart';
import 'comment_field.dart';

/// A top-level comment with its replies, in one box (Settings-6): age and
/// text, then a "💬 2" chip that opens and closes the replies, and at the
/// end of the open thread a reply field. The user's own comments have a ✏️
/// that opens Edit Comment.
class CommentThread extends StatelessWidget {
  const CommentThread({
    super.key,
    required this.thread,
    required this.open,
    required this.onToggle,
    required this.onEdit,
    required this.replyController,
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
  final bool sendingReply;
  final VoidCallback onSendReply;
  final int maxLength;

  /// For tests. Defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: CommunityTokens.commentDividerIndent,
      endIndent: CommunityTokens.commentDividerIndent,
      color: CommunityColors.border(context),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: CommunityColors.border(context)),
        borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: CommunityTokens.commentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommentBody(comment: thread, onEdit: onEdit, now: now, topLevel: true),
                const SizedBox(height: CommunityTokens.commentGap),
                _RepliesChip(count: thread.replies.length, open: open, onTap: onToggle),
              ],
            ),
          ),
          if (open) ...[
            for (final reply in thread.replies) ...[
              divider,
              Padding(
                padding: CommunityTokens.commentPadding,
                child: _CommentBody(comment: reply, onEdit: onEdit, now: now, topLevel: false),
              ),
            ],
            divider,
            Padding(
              padding: CommunityTokens.commentPadding,
              child: CommentField(
                controller: replyController,
                sending: sendingReply,
                onSend: onSendReply,
                maxLength: maxLength,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Age (with "· edited"), the ✏️ for the user's own comment, and the text,
/// or "Comment deleted" in its place.
class _CommentBody extends StatelessWidget {
  const _CommentBody({required this.comment, required this.onEdit, required this.now, required this.topLevel});

  final FeedbackComment comment;
  final ValueChanged<FeedbackComment> onEdit;
  final DateTime? now;

  /// Top-level text is a step bolder than replies, as in Settings-6.
  final bool topLevel;

  /// The ✏️'s tap area. Smaller than 48 px so the row keeps Figma's height.
  static const _editButtonSize = Size(40, 32);

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = CommunityColors.muted(context);
    final age = formatAge(l, comment.createdAt, now: now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _editButtonSize.height,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  comment.edited ? '$age · ${l.edited}' : age,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: muted,
                  ),
                ),
              ),
              if (comment.isMine)
                IconButton(
                  tooltip: l.editComment,
                  onPressed: () => onEdit(comment),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(_editButtonSize),
                  icon: const EmojiText('✏️', size: 16),
                ),
            ],
          ),
        ),
        if (comment.deleted)
          Text(
            l.commentDeleted,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: muted,
            ),
          )
        else
          Text(
            comment.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: topLevel ? FontWeight.w500 : FontWeight.w400,
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}

/// "💬 2 ▼": opens the replies (▼) or closes them (▲). Without replies it
/// shows only 💬 and opens the reply field.
class _RepliesChip extends StatelessWidget {
  const _RepliesChip({required this.count, required this.open, required this.onTap});

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final label = open ? l.hideReplies : (count == 0 ? l.reply : l.showReplies(count));
    return Semantics(
      button: true,
      expanded: open,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: CommunityColors.border(context)),
          borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(
              minWidth: CommunityTokens.repliesChipSize.width,
              minHeight: CommunityTokens.repliesChipSize.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmojiText('💬', size: 16),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
                Icon(
                  open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
