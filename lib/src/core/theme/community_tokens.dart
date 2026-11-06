import 'package:flutter/material.dart';

/// Spacing, radius and size tokens from the Figma file.
abstract final class CommunityTokens {
  static const screenPadding = 6.0;
  static const cardGap = 8.0;
  static const cardRadius = 5.0;
  static const cardPadding = EdgeInsets.fromLTRB(12, 6, 8, 6);
  static const cardSectionGap = 8.0;
  static const iconSize = 24.0;
  static const reactionChipSize = Size(40, 26);

  /// Link rows such as "all Feedback": one block with 1 px gaps.
  static const rowHeight = 44.0;
  static const rowGap = 1.0;
  static const rowRadius = 5.0;
  static const rowPadding = EdgeInsets.only(left: 12, right: 5);
  static const rowEmojiSize = 20.0;
  static const rowEmojiGap = 10.0;

  static const sheetRadius = 5.0;
  static const buttonSize = Size(105, 42);
  static const buttonRadius = 5.0;

  // New Feedback form. Measured from the Figma PNG exports (frames 1:144
  // and 1:181), not read from Figma itself.
  static const formPadding = 14.0;
  static const fieldMinHeight = 47.0;
  static const fieldRadius = 3.0;
  static const fieldPadding = EdgeInsets.symmetric(horizontal: 17, vertical: 10);
  static const topicPillMinWidth = 176.0;
  static const topicMenuMinWidth = 182.0;
  static const topicRowHeight = 42.0;
  static const topicRadius = 8.0;

  /// The ✗ / ✓ buttons at the bottom of a form.
  static const actionButtonSize = Size(61, 59);
  static const actionButtonRadius = 9.0;
  static const actionButtonGap = 80.0;

  /// Space under the ✗ / ✓ buttons on phones without a bottom inset.
  static const actionsBottomGap = 16.0;
}

/// Colours with no matching role in the host theme. The dark values are the
/// Figma values; the light values are darker so they stay readable on white.
class CommunityColors {
  const CommunityColors._({
    required this.statusPlanned,
    required this.statusInProgress,
    required this.statusDone,
    required this.cost,
    required this.reacted,
    required this.submit,
  });

  static const _dark = CommunityColors._(
    statusPlanned: Color(0xFF0088FF),
    statusInProgress: Color(0xFFFFCC00),
    statusDone: Color(0xFF00C00D),
    cost: Color(0xFFFF0000),
    reacted: Color(0xFFFF0000),
    submit: Color(0xFF4BE000),
  );

  static const _light = CommunityColors._(
    statusPlanned: Color(0xFF0066CC),
    statusInProgress: Color(0xFF9A7400),
    statusDone: Color(0xFF00850A),
    cost: Color(0xFFD00000),
    reacted: Color(0xFFD00000),
    submit: Color(0xFF2E8B00),
  );

  static CommunityColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  final Color statusPlanned;
  final Color statusInProgress;
  final Color statusDone;
  final Color cost;
  final Color reacted;

  /// The ✓ of a form's submit button.
  final Color submit;

  /// Card and chip borders: Figma's #404040 on black is white at 25%.
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

  /// Text field borders: Figma's #004C93 is #0088FF at 55% on black.
  static Color fieldBorder(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.55);

  /// Secondary text such as the age: Figma's #9B9B9B on black.
  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
}
