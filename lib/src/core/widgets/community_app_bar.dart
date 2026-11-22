import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/community_localizations.dart';
import '../navigation/community_navigator.dart';
import '../theme/community_icons.dart';
import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import 'refresh_buttons.dart';
import 'emoji_text.dart';

/// Header of every package screen: back arrow and an emoji title.
class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({
    super.key,
    required this.emoji,
    required this.title,
    this.actions,
    this.onBack,
    this.titleColor,
    this.emojiSize = 27,
    this.titleWeight = FontWeight.w600,
    this.refreshed = false,
  });

  /// The refreshed look: 56 high for 48 px buttons, a rounded back arrow,
  /// the title at 17 SemiBold. A flag rather than [CommunityRefresh],
  /// because the Scaffold reads [preferredSize] without a context.
  final bool refreshed;

  final String emoji;
  final String title;

  /// For example a status colour. Defaults to the app bar's text colour.
  final Color? titleColor;
  final List<Widget>? actions;

  /// Replaces the default back, for screens that ask before leaving.
  final VoidCallback? onBack;

  /// Screen titles have a 27 px emoji in SemiBold; the detail header's
  /// status a 20 px one in Medium (specs.md §2).
  final double emojiSize;
  final FontWeight titleWeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(refreshed ? RefreshTokens.headerHeight : CommunityTokens.headerHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    if (refreshed) return _refreshed(context, color);
    return AppBar(
      toolbarHeight: CommunityTokens.headerHeight,
      centerTitle: true,
      leadingWidth: CommunityTokens.headerHeight,
      leading: IconButton(
        tooltip: CommunityLocalizations.of(context).back,
        onPressed: onBack ?? () => CommunityNavigator.back(context),
        constraints: const BoxConstraints.tightFor(
          width: CommunityTokens.headerHeight,
          height: CommunityTokens.headerHeight,
        ),
        padding: const EdgeInsets.only(left: CommunityTokens.backArrowInset),
        alignment: Alignment.centerLeft,
        icon: SvgPicture.asset(
          CommunityIcons.arrowLeft,
          package: CommunityIcons.package,
          width: CommunityTokens.iconSize,
          height: CommunityTokens.iconSize,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(emoji, size: emojiSize),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: titleWeight,
                color: titleColor ?? color,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  Widget _refreshed(BuildContext context, Color color) {
    return AppBar(
      toolbarHeight: RefreshTokens.headerHeight,
      centerTitle: true,
      leadingWidth: RefreshTokens.minTarget + 8,
      titleSpacing: 8,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: RefreshIconButton(
          tooltip: CommunityLocalizations.of(context).back,
          onPressed: onBack ?? () => CommunityNavigator.back(context),
          color: color,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(emoji, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RefreshTokens.title(context, color: titleColor ?? color),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
