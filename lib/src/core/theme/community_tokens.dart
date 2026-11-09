import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';

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

  /// The list toolbar under the header: sort, filter and search on the
  /// left, + on the right. Measured from the PNG export of frame 1:426:
  /// icon centres 30, 102 and 179 px from the left (a 26 px gap between the
  /// 48 px buttons puts them at 30, 104 and 178), the + 27 px from the right.
  static const toolbarHeight = 46.0;
  static const toolbarPadding = EdgeInsets.only(left: 6, right: 13);
  static const toolbarButtonGap = 26.0;
  static const toolbarIconSize = 21.0;
  static const sortIconSize = Size(19, 12);
  static const filterIconSize = Size(19, 21);
  static const searchIconSize = Size(20, 21);

  /// The search field that replaces the toolbar's buttons.
  static const searchFieldHeight = 38.0;
  static const searchFieldPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 8);

  /// The sort and filter menus (not in Figma; built like the topic menu).
  static const menuRowPadding = 16.0;
  static const menuHeaderHeight = 32.0;
  static const menuTickSize = 20.0;

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

  // Problem form, measured from the PNG exports of frames Settings-3 and
  // Settings-4: fields 46 px high and 5 px apart; the device boxes are
  // 93, 79 and 189 px wide with 4 px between them.
  static const problemFieldGap = 5.0;
  static const deviceBoxGap = 4.0;
  static const deviceBoxFlex = (os: 93, app: 79, phone: 189);
  static const deviceBoxPadding = EdgeInsets.fromLTRB(7, 3, 7, 4);

  /// Screen picker rows: each level is indented this much more.
  static const screenIndent = 20.0;

  /// The ✗ / ✓ buttons at the bottom of a form.
  static const actionButtonSize = Size(61, 59);
  static const actionButtonRadius = 9.0;
  static const actionButtonGap = 80.0;

  /// The red 🗑 between ✗ and ✓ (Edit Comment, Settings-12): 43 px square,
  /// about 30 px from each.
  static const deleteButtonSize = Size(43, 43);
  static const deleteButtonGap = 30.0;

  /// Space under the ✗ / ✓ buttons on phones without a bottom inset.
  static const actionsBottomGap = 16.0;

  // Feedback detail and comments, measured from the PNG export of
  // Settings-6: the new comment field 45 px high, a reply field 32 px, the
  // replies chip 64 × 26, dividers inset about 10 px in the thread box.
  static const commentPadding = EdgeInsets.fromLTRB(12, 8, 12, 10);
  static const commentFieldMinHeight = 45.0;
  static const replyFieldMinHeight = 32.0;
  static const repliesChipSize = Size(64, 26);
  static const commentDividerIndent = 10.0;
  static const commentGap = 6.0;
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

  /// The colour of [status] on cards and in the filter.
  Color status(FeedbackStatus status) => switch (status) {
    FeedbackStatus.planned => statusPlanned,
    FeedbackStatus.inProgress => statusInProgress,
    FeedbackStatus.done => statusDone,
  };

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
