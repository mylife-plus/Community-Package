import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';

/// The text field of the forms: one line at first, growing with the text.
class CommunityTextField extends StatelessWidget {
  const CommunityTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.enabled = true,
  });

  /// Not tuned yet: how many characters before [maxLength] the counter shows.
  static const counterThreshold = 200;

  /// Not tuned yet: lines the field grows to before it scrolls.
  static const maxLines = 8;

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = CommunityColors.muted(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface,
      ),
      // The count only shows close to the limit.
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        if (maxLength == null || currentLength < maxLength - counterThreshold) return null;
        return Text(
          '$currentLength / $maxLength',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        );
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: muted,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        isDense: true,
        contentPadding: CommunityTokens.fieldPadding,
        constraints: const BoxConstraints(minHeight: CommunityTokens.fieldMinHeight),
        enabledBorder: border(CommunityColors.fieldBorder(context)),
        disabledBorder: border(CommunityColors.fieldBorder(context)),
        focusedBorder: border(theme.colorScheme.primary),
      ),
    );
  }
}
