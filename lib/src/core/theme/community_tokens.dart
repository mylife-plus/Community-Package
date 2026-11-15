import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';

/// Spacing, radius and size tokens from the Figma file.
abstract final class CommunityTokens {
  /// Figma's line height: 20 px for 16 px text, the same ratio at every
  /// size, with the extra space split evenly above and below the glyphs.
  static const lineHeight = 1.25;

  /// Long reading text (privacy notice, Rules) is set looser than Figma's
  /// 1.25, for comfortable reading of whole paragraphs (WCAG 1.4.8:
  /// https://www.w3.org/WAI/WCAG22/Understanding/visual-presentation.html).
  static const readingLineHeight = 1.4;

  /// The header: 44 high, the back arrow's 24 px box 8 from the left edge.
  /// Its tap area stays 44 px square.
  static const headerHeight = 44.0;
  static const backArrowInset = 8.0;

  /// Lists: the toolbar starts 14.5 under the header, the first card 2
  /// under the toolbar (Settings-15: toolbar icons 59.5 and the first card
  /// 84.5 below the title's centre).
  static const listToolbarTop = 14.5;
  static const listTop = 2.0;

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

  /// Behind the edit sheets: black at 70% (Settings-9, -12, -14).
  static const sheetScrim = Color(0xB3000000);
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

  /// Form fields are 368 wide on a 390 px phone (Settings-1 to -4).
  static const formFieldInset = 11.0;
  static const fieldMinHeight = 47.0;
  static const fieldRadius = 4.0;
  static const fieldPadding = EdgeInsets.symmetric(horizontal: 17, vertical: 10);
  static const topicPillMinWidth = 176.0;
  static const topicMenuMinWidth = 182.0;
  static const topicRowHeight = 43.0;
  static const topicRadius = 10.0;

  /// The open topic menu's bottom corners (its top ones are [topicRadius]).
  static const topicMenuBottomRadius = 9.0;

  // Problem form (Settings-3 and -4): fields 47 px high and 4 px apart; the
  // device boxes are 93, 79 and 189 px wide with 4 px between them, the
  // caption at (6, 3) and the value at (9, 18), counted from the outside of
  // the 1 px border.
  static const problemFieldGap = 4.0;
  static const deviceBoxGap = 4.0;
  static const deviceBoxFlex = (os: 93, app: 79, phone: 189);
  static const deviceBoxPadding = EdgeInsets.fromLTRB(5, 2, 5, 3);
  static const deviceValueIndent = 3.0;

  /// Screen picker rows: each level is indented this much more.
  static const screenIndent = 20.0;

  /// The ✗ / ✓ buttons at the bottom of a form, with Figma's drop shadow.
  static const actionButtonSize = Size(61, 59);
  static const actionButtonRadius = 11.0;
  static const actionButtonGap = 80.0;
  static const actionButtonShadow = BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 4);

  /// The red 🗑 between ✗ and ✓ (Edit Comment, Settings-12): 43 × 42,
  /// about 30 px from each.
  static const deleteButtonSize = Size(43, 42);
  static const deleteButtonGap = 30.0;

  /// Space under the ✗ / ✓ buttons on phones without a bottom inset.
  static const actionsBottomGap = 16.0;

  // Feedback detail and comments, measured from the PNG export of
  // Settings-6: the new comment field 45 px high, a reply field 32 px, the
  // replies chip 65 × 26 at 10 from the box's edge and 4 above the
  // divider, dividers 352 wide (11 in from the left, 15 from the right),
  // the reply "+" on a 56 px row.
  static const commentPadding = EdgeInsets.fromLTRB(12, 8, 12, 10);
  static const commentFieldMinHeight = 45.0;
  static const replyFieldMinHeight = 32.0;
  static const repliesChipSize = Size(65, 26);
  static const repliesChipInset = 10.0;
  static const repliesChipToDivider = 4.0;
  static const commentDividerIndent = 11.0;
  static const commentDividerEndIndent = 15.0;
  static const commentGap = 6.0;
  static const replyAddRowHeight = 56.0;

  /// The detail card's distance to the comment toolbar, and the toolbar's to
  /// the first comment (Settings-6: the card's bottom is 32 above the
  /// toolbar's centre, the box 34 below it).
  static const detailCardToToolbar = 9.0;
  static const detailToolbarToComments = 11.0;
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
    required this.cancel,
  });

  static const _dark = CommunityColors._(
    statusPlanned: Color(0xFF0088FF),
    statusInProgress: Color(0xFFFFCC00),
    statusDone: Color(0xFF00C00D),
    cost: Color(0xFFFF0000),
    reacted: Color(0xFFFF0000),
    submit: Color(0xFF4BE000),
    cancel: Color(0xFFFF0000),
  );

  static const _light = CommunityColors._(
    statusPlanned: Color(0xFF0066CC),
    // 4.5:1 on white and on a light grey screen (#9A7400 was 4.3).
    statusInProgress: Color(0xFF876600),
    statusDone: Color(0xFF00850A),
    cost: Color(0xFFD00000),
    reacted: Color(0xFFD00000),
    submit: Color(0xFF2E8B00),
    cancel: Color(0xFFD00000),
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

  /// The ✗ of a form's cancel button and the "agree to Rules" link
  /// (specs.md: #FF0000 on dark).
  final Color cancel;

  /// A solid grey: [amount] of onSurface over the surface colour. On
  /// Figma's black it gives the exact Figma grey; in light mode the
  /// matching shade on white.
  static Color _grey(BuildContext context, int figmaGrey) {
    final scheme = Theme.of(context).colorScheme;
    return Color.alphaBlend(scheme.onSurface.withValues(alpha: figmaGrey / 0xFF), scheme.surface);
  }

  /// Inactive icons (sort, filter, search, +): Figma's #909090.
  static Color icon(BuildContext context) => _grey(context, 0x90);

  /// Light mode only: [color] mixed over the surface at [alpha], or at
  /// just enough more for a contrast of [ratio] against both the surface
  /// and the screen background. Dark mode keeps Figma's mix. WCAG 1.4.3
  /// (text 4.5:1) and 1.4.11 (field borders 3:1):
  /// https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
  /// https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
  static Color _readable(BuildContext context, Color color, double alpha, double ratio) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    Color mix(double a) => Color.alphaBlend(color.withValues(alpha: a), surface);
    if (theme.brightness == Brightness.dark) return mix(alpha);
    final backgrounds = [surface, theme.scaffoldBackgroundColor];
    bool enough(Color c) => backgrounds.every((bg) => _contrast(c, bg) >= ratio);
    if (enough(mix(alpha))) return mix(alpha);
    if (!enough(mix(1))) return mix(1);
    var low = alpha;
    var high = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (enough(mix(mid))) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return mix(high);
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Small captions (OS / App / Phone): Figma's #909090; in light mode at
  /// least 4.5:1.
  static Color caption(BuildContext context) =>
      _readable(context, Theme.of(context).colorScheme.onSurface, 0x90 / 0xFF, 4.5);

  /// The comment "+" (toolbar and under a thread): Figma's #A4A4A4.
  static Color commentAdd(BuildContext context) => _grey(context, 0xA4);

  /// Dividers between comments: Figma's #5C5C5C.
  static Color commentDivider(BuildContext context) => _grey(context, 0x5C);

  /// The edit Comment field's border: Figma's #404040; in light mode at
  /// least 3:1.
  static Color commentFieldBorder(BuildContext context) =>
      _readable(context, Theme.of(context).colorScheme.onSurface, 0x40 / 0xFF, 3);

  /// Placeholders and field labels: Figma's #898989; in light mode at least
  /// 4.5:1.
  static Color placeholder(BuildContext context) =>
      _readable(context, Theme.of(context).colorScheme.onSurface, 0x89 / 0xFF, 4.5);

  /// The device line on Problem cards: Figma's #BABABA.
  static Color deviceLine(BuildContext context) => _grey(context, 0xBA);

  /// Card and chip borders: Figma's #404040 on black is white at 25%.
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

  /// Text field borders: Figma's #004C93 is #0088FF at 55% on black. In
  /// light mode at least 3:1.
  static Color fieldBorder(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) return theme.colorScheme.primary.withValues(alpha: 0.55);
    return _readable(context, theme.colorScheme.primary, 0.55, 3);
  }

  /// Secondary text such as the age: Figma's #9B9B9B on black. In light
  /// mode at least 4.5:1, also on the screen background.
  static Color muted(BuildContext context) => _translucentText(context, 0.6);

  /// Dark mode: onSurface at Figma's [alpha], as drawn so far. Light mode:
  /// the same mix, raised just enough for 4.5:1 (see [_readable]).
  static Color _translucentText(BuildContext context, double alpha) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Theme.of(context).brightness == Brightness.dark
        ? onSurface.withValues(alpha: alpha)
        : _readable(context, onSurface, alpha, 4.5);
  }
}
