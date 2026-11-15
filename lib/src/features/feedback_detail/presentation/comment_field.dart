import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/widgets/community_text_field.dart';

/// A "new Comment..." field (Settings-6): the large one under the toolbar,
/// or the smaller reply field at the end of a thread. A send button shows
/// inside it once there is text. While [sending] the field is locked; the
/// screen shows the loading dialog.
class CommentField extends StatelessWidget {
  const CommentField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.sending,
    required this.maxLength,
    this.large = false,
    this.autofocus = false,
  });

  /// Not tuned yet: lines the field grows to before it scrolls.
  static const maxLines = 6;

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final int maxLength;

  /// The new comment field under the toolbar; otherwise a reply field.
  final bool large;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final fontSize = large ? 20.0 : 16.0;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
      borderSide: BorderSide(color: color),
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return TextField(
          controller: controller,
          enabled: !sending,
          autofocus: autofocus,
          maxLength: maxLength,
          minLines: 1,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          buildCounter: CommunityTextField.counter,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface,
          ),
          // Every part of the decoration is set, so a host's
          // InputDecorationTheme cannot add a second box (as Inventory's
          // did inside the Problem steps, S4).
          decoration: InputDecoration(
            hintText: l.newCommentHint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: CommunityColors.placeholder(context),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            isDense: true,
            contentPadding: large
                ? CommunityTokens.fieldPadding
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: BoxConstraints(
              minHeight: large ? CommunityTokens.commentFieldMinHeight : CommunityTokens.replyFieldMinHeight,
            ),
            suffixIcon: hasText && !sending
                ? IconButton(
                    tooltip: l.sendComment,
                    onPressed: onSend,
                    icon: Icon(Icons.send_rounded, size: 22, color: theme.colorScheme.primary),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 32),
            border: border(CommunityColors.fieldBorder(context)),
            enabledBorder: border(CommunityColors.fieldBorder(context)),
            disabledBorder: border(CommunityColors.fieldBorder(context)),
            focusedBorder: border(theme.colorScheme.primary),
          ),
        );
      },
    );
  }
}
