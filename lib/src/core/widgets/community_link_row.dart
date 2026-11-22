import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/community_icons.dart';
import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import 'emoji_text.dart';
import 'refresh_buttons.dart';

/// Link rows stacked into one rounded block, 1 px apart.
class CommunityLinkGroup extends StatelessWidget {
  const CommunityLinkGroup({super.key, required this.rows});

  final List<CommunityLinkRow> rows;

  /// The refreshed rows: 56 high, the faint divider starting under the label.
  static const refreshedRowHeight = 56.0;
  static const _refreshedEmojiSize = 22.0;
  static const _refreshedEmojiGap = 12.0;
  static const _dividerIndent = RefreshTokens.cardPadding + _refreshedEmojiSize + _refreshedEmojiGap;

  @override
  Widget build(BuildContext context) {
    if (CommunityRefresh.of(context)) return _refreshed(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(CommunityTokens.rowRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: CommunityTokens.rowGap), rows[i]],
        ],
      ),
    );
  }
}

extension on CommunityLinkGroup {
  /// The refreshed group: one card (radius 16, a faint edge), the rows
  /// split by faint dividers.
  Widget _refreshed(BuildContext context) {
    final border = RefreshColors.faintBorder(context);
    return Material(
      color: RefreshColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RefreshTokens.cardRadius),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: CommunityLinkGroup._dividerIndent, color: border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// One tappable row: emoji, label and an arrow.
class CommunityLinkRow extends StatelessWidget {
  const CommunityLinkRow({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    if (CommunityRefresh.of(context)) return _refreshed(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: CommunityTokens.rowHeight,
          child: Padding(
            padding: CommunityTokens.rowPadding,
            child: Row(
              children: [
                EmojiText(emoji, size: CommunityTokens.rowEmojiSize),
                const SizedBox(width: CommunityTokens.rowEmojiGap),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  CommunityIcons.arrowRight,
                  package: CommunityIcons.package,
                  width: CommunityTokens.iconSize,
                  height: CommunityTokens.iconSize,
                  colorFilter: ColorFilter.mode(onSurface, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on CommunityLinkRow {
  /// The refreshed row: on the group's card, 56 high, emoji 22, the label
  /// at 15 Medium, a rounded chevron in the secondary text colour.
  Widget _refreshed(BuildContext context) {
    final card = RefreshColors.card(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: CommunityLinkGroup.refreshedRowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RefreshTokens.cardPadding, vertical: 8),
          child: Row(
            children: [
              EmojiText(emoji, size: CommunityLinkGroup._refreshedEmojiSize),
              const SizedBox(width: CommunityLinkGroup._refreshedEmojiGap),
              Expanded(
                child: Text(
                  sentenceCase(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RefreshTokens.body(context, weight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24, color: RefreshColors.meta(context, on: card)),
            ],
          ),
        ),
      ),
    );
  }
}
