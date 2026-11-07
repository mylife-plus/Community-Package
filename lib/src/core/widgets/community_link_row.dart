import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/community_icons.dart';
import '../theme/community_tokens.dart';
import 'emoji_text.dart';

/// Link rows stacked into one rounded block, 1 px apart.
class CommunityLinkGroup extends StatelessWidget {
  const CommunityLinkGroup({super.key, required this.rows});

  final List<CommunityLinkRow> rows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CommunityTokens.rowRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: CommunityTokens.rowGap),
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
