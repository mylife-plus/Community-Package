import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_icons.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/emoji_text.dart';
import '../../../core/widgets/inner_shadow.dart';
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
    final theme = Theme.of(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: CommunityTokens.commentDividerIndent,
      endIndent: CommunityTokens.commentDividerEndIndent,
      color: CommunityColors.commentDivider(context),
    );
    final l = CommunityLocalizations.of(context);

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
            padding: CommunityTokens.commentPadding.copyWith(bottom: 0),
            child: _CommentBody(comment: thread, onEdit: onEdit, now: now, topLevel: true),
          ),
          const SizedBox(height: CommunityTokens.commentGap),
          // Settings-6: the chip sits 2 further out than the text.
          Padding(
            padding: EdgeInsets.only(
              left: CommunityTokens.repliesChipInset,
              bottom: open ? CommunityTokens.repliesChipToDivider : CommunityTokens.commentPadding.bottom,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RepliesChip(count: thread.replies.length, open: open, onTap: onToggle),
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
            if (replying)
              Padding(
                padding: CommunityTokens.commentPadding,
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
            else
              SizedBox(
                height: CommunityTokens.replyAddRowHeight,
                child: Center(
                  child: IconButton(
                    tooltip: l.reply,
                    onPressed: onReply,
                    icon: SvgPicture.asset(
                      CommunityIcons.add,
                      package: CommunityIcons.package,
                      width: CommunityTokens.toolbarIconSize,
                      height: CommunityTokens.toolbarIconSize,
                      colorFilter: ColorFilter.mode(CommunityColors.commentAdd(context), BlendMode.srcIn),
                    ),
                  ),
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
              fontWeight: topLevel ? FontWeight.w500 : FontWeight.w300,
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}

/// "💬 2 ▼": opens the replies (▼) or closes them (▲). Without replies it
/// shows only 💬 and opens the reply field. Like the heart chip, it has
/// Figma's inner shadow and no border.
class _RepliesChip extends StatelessWidget {
  const _RepliesChip({required this.count, required this.open, required this.onTap});

  final int count;
  final bool open;
  final VoidCallback onTap;

  /// Settings-6: a ▼ about 12 × 8.5 in Figma's icon grey.
  static const _arrowSize = Size(12, 8.5);

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
        borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: InnerShadow(
            radius: CommunityTokens.cardRadius,
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
                  const SizedBox(width: 6),
                  CustomPaint(
                    size: _arrowSize,
                    painter: _ArrowPainter(up: open, color: CommunityColors.icon(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.up != up || old.color != color;
}
