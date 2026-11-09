import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';
import 'emoji_text.dart';

// The drop-down menus of the list toolbars (sort and filter). Not in Figma;
// built like the New Feedback topic menu (frame 1:144): surface, primary
// outline and dividers, 8 px corners, 42 px rows.

/// The outlined box, with a divider between rows. Scrolls when the screen
/// is too short for it.
class CommunityMenuFrame extends StatelessWidget {
  const CommunityMenuFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Container(height: 1, color: scheme.primary);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: CommunityTokens.topicMenuMinWidth),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CommunityTokens.topicRadius),
          side: BorderSide(color: scheme.primary),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) divider,
                  children[i],
                ],
              ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: CommunityTokens.menuHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CommunityColors.muted(context),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = this.emoji;
    final style = theme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    return Semantics(
      selected: centered ? null : selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: CommunityTokens.topicRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
          child: Row(
            mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (emoji != null) ...[EmojiText(emoji, size: 16), const SizedBox(width: 6)],
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
                const SizedBox(width: 12),
                // Space kept when not ticked, so the menu does not change width.
                SizedBox(
                  width: CommunityTokens.menuTickSize,
                  child: selected
                      ? Icon(Icons.check, size: CommunityTokens.menuTickSize, color: theme.colorScheme.primary)
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
