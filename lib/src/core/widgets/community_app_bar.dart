import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/community_localizations.dart';
import '../navigation/community_navigator.dart';
import '../theme/community_tokens.dart';
import 'emoji_text.dart';

/// Header of every package screen: back arrow and an emoji title.
class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key, required this.emoji, required this.title, this.actions});

  final String emoji;
  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        tooltip: CommunityLocalizations.of(context).back,
        onPressed: () => CommunityNavigator.back(context),
        icon: SvgPicture.asset(
          'assets/icons/arrow_left.svg',
          package: 'community_package',
          width: CommunityTokens.iconSize,
          height: CommunityTokens.iconSize,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(emoji, size: 27),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
