import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/widgets/community_form_actions.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/community_text_field.dart';
import '../../../data/models/feedback_comment.dart';

/// What the user chose in [EditCommentSheet]. Closing it any other way
/// gives null.
sealed class EditCommentResult {
  const EditCommentResult();
}

/// Save the comment with [text], trimmed and changed.
class SaveCommentEdit extends EditCommentResult {
  const SaveCommentEdit(this.text);

  final String text;
}

/// Delete the comment; the user already confirmed.
class DeleteCommentEdit extends EditCommentResult {
  const DeleteCommentEdit();
}

/// "edit Comment" (Settings-12): the comment's text in a field, then ✗,
/// a red 🗑 and ✓. 🗑 asks before deleting, saying whether replies stay.
class EditCommentSheet extends StatefulWidget {
  const EditCommentSheet({super.key, required this.comment, required this.maxLength});

  final FeedbackComment comment;
  final int maxLength;

  @override
  State<EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<EditCommentSheet> {
  late final _controller = TextEditingController(text: widget.comment.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = CommunityLocalizations.of(context);
    final confirmed = await showCommunityConfirm(
      context,
      title: widget.comment.replies.isEmpty ? l.deleteCommentTitle : l.deleteCommentKeepsReplies,
      confirmLabel: l.delete,
      cancelLabel: l.keep,
    );
    if (confirmed && mounted) closePopup(context, const DeleteCommentEdit());
  }

  void _save() {
    final text = _controller.text.trim();
    // Saving the same text is the same as closing.
    closePopup(context, text == widget.comment.text ? null : SaveCommentEdit(text));
  }

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // Above the keyboard while typing.
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CommunityTokens.screenPadding,
            28,
            CommunityTokens.screenPadding,
            CommunityTokens.actionsBottomGap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editCommentTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 28),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CommunityTextField(
                      controller: _controller,
                      hint: l.newCommentHint,
                      maxLength: widget.maxLength,
                    ),
                    const SizedBox(height: 24),
                    CommunityFormActions(
                      cancelLabel: l.cancel,
                      submitLabel: l.save,
                      deleteLabel: l.delete,
                      onCancel: () => closePopup(context),
                      onDelete: _delete,
                      onSubmit: value.text.trim().isEmpty ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
