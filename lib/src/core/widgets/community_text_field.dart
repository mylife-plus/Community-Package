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
    this.leading,
    this.borderColor,
  });

  /// The counter shows from this share of [maxLength] on: 80 of 100, 400
  /// of 500.
  static const counterFrom = 0.8;

  /// Not tuned yet: lines the field grows to before it scrolls.
  static const maxLines = 8;

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final bool enabled;

  /// Always shown before the text and the hint, like the 📲 on the screen
  /// field. A `prefix` would show only while focused or filled.
  final Widget? leading;

  /// The border while not focused. Defaults to the forms' blue; sheets use
  /// Figma's greys.
  final Color? borderColor;

  /// The typed text.
  static TextStyle? textStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle? hintStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: CommunityColors.placeholder(context),
  );

  /// The count, shown only close to the limit.
  static Widget? counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < maxLength * counterFrom) return null;
    return Text(
      '$currentLength / $maxLength',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CommunityColors.muted(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
      borderSide: BorderSide(color: color),
    );

    final leading = this.leading;
    const padding = CommunityTokens.fieldPadding;

    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: textStyle(context),
      buildCounter: counter,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle(context),
        filled: true,
        fillColor: theme.colorScheme.surface,
        isDense: true,
        contentPadding: leading == null ? padding : padding.copyWith(left: 0),
        prefixIcon: leading == null
            ? null
            : Padding(padding: EdgeInsets.only(left: padding.left, right: 6), child: leading),
        prefixIconConstraints: const BoxConstraints(),
        constraints: const BoxConstraints(minHeight: CommunityTokens.fieldMinHeight),
        enabledBorder: border(borderColor ?? CommunityColors.fieldBorder(context)),
        disabledBorder: border(borderColor ?? CommunityColors.fieldBorder(context)),
        focusedBorder: border(theme.colorScheme.primary),
      ),
    );
  }
}
