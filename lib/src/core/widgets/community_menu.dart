import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import 'emoji_text.dart';

// The drop-down menus (sort, filter and the pickers in sheets). Not in
// Figma; in the refreshed look: a raised surface with radius 12 and a faint
// edge, 48 px rows with a ripple, and group titles in the meta style.

/// The raised box of a menu. Scrolls when the screen is too short for it.
class CommunityMenuFrame extends StatelessWidget {
  const CommunityMenuFrame({super.key, required this.children});

  final List<Widget> children;

  /// Above and below the rows.
  static const _verticalPadding = 8.0;

  /// The menu's colour, for text that must read on it.
  static Color background(BuildContext context) => RefreshColors.sheet(context);

  /// [color] (a status colour, the primary for reset) raised to 4.5:1 on
  /// the menu.
  static Color readable(BuildContext context, Color color) =>
      RefreshColors.readable(color, Theme.of(context).colorScheme.onSurface, background(context), 4.5);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: CommunityTokens.topicMenuMinWidth),
      child: Material(
        color: background(context),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RefreshTokens.controlRadius),
          side: BorderSide(color: RefreshColors.faintBorder(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// A group title inside the filter menu.
class CommunityMenuHeader extends StatelessWidget {
  const CommunityMenuHeader(this.label, {super.key});

  final String label;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: RefreshTokens.meta(context, on: CommunityMenuFrame.background(context), weight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// One row of a menu: an optional emoji, the label and a tick when
/// [selected].
class CommunityMenuRow extends StatelessWidget {
  const CommunityMenuRow({
    super.key,
    this.emoji,
    required this.label,
    this.selected = false,
    this.centered = false,
    required this.onTap,
  });

  final String? emoji;
  final Text label;
  final bool selected;

  /// A lone action such as reset: centred, no tick.
  final bool centered;
  final VoidCallback onTap;

  static const _emojiSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = this.emoji;
    final style = RefreshTokens.body(context, weight: FontWeight.w500)?.copyWith(height: 1.2);
    return Semantics(
      selected: centered ? null : selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: RefreshTokens.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
          child: Row(
            mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (emoji != null) ...[EmojiText(emoji, size: _emojiSize), const SizedBox(width: 12)],
              // The only flexible child, so the label gets all the room left.
              Flexible(
                fit: centered ? FlexFit.loose : FlexFit.tight,
                child: DefaultTextStyle.merge(
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: label,
                ),
              ),
              if (!centered) ...[
                const SizedBox(width: 16),
                // Space kept when not ticked, so the menu does not change width.
                SizedBox(
                  width: CommunityTokens.menuTickSize,
                  child: selected
                      ? Icon(Icons.check_rounded, size: CommunityTokens.menuTickSize, color: theme.colorScheme.primary)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
