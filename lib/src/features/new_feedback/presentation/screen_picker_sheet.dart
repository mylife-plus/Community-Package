import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/refresh_buttons.dart';
import '../../../core/widgets/emoji_text.dart';
import '../domain/screen_tree.dart';

/// Every screen of the app as one indented list. Tapping a row, parent rows
/// included, closes the sheet with that screen; dragging it down closes it
/// with null.
class ScreenPickerSheet extends StatelessWidget {
  const ScreenPickerSheet({super.key, required this.screens, this.selected});

  final List<ScreenChoice> screens;
  final ScreenChoice? selected;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    if (CommunityRefresh.of(context)) return _refreshed(context, l);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 20, 9, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmojiText('📲', size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l.selectScreen,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CommunityTokens.rowRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < screens.length; i++) ...[
                    if (i > 0) const SizedBox(height: CommunityTokens.rowGap),
                    _ScreenRow(
                      choice: screens[i],
                      selected: screens[i] == selected,
                      onTap: () => closePopup(context, screens[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on ScreenPickerSheet {
  /// The refreshed sheet (opened with `refreshed: true`): the title at 17
  /// under the handle, the screens in one card (radius 16, a faint edge),
  /// 24 from the sheet's sides.
  Widget _refreshed(BuildContext context, CommunityLocalizations l) {
    final border = RefreshColors.faintBorder(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(RefreshTokens.sheetPadding, 4, RefreshTokens.sheetPadding, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmojiText('📲', size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(sentenceCase(l.selectScreen), style: RefreshTokens.title(context))),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              RefreshTokens.sheetPadding,
              0,
              RefreshTokens.sheetPadding,
              RefreshTokens.sheetPadding + MediaQuery.paddingOf(context).bottom,
            ),
            child: Material(
              color: RefreshColors.card(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RefreshTokens.cardRadius),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < screens.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: border),
                    _ScreenRow(
                      choice: screens[i],
                      selected: screens[i] == selected,
                      onTap: () => closePopup(context, screens[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenRow extends StatelessWidget {
  const _ScreenRow({required this.choice, required this.selected, required this.onTap});

  final ScreenChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (CommunityRefresh.of(context)) return _refreshed(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CommunityTokens.rowHeight),
            child: Padding(
              padding: CommunityTokens.rowPadding.copyWith(
                left: CommunityTokens.rowPadding.left + choice.depth * CommunityTokens.screenIndent,
                right: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      choice.label(context),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        // Top-level screens stand out from the screens under them.
                        fontWeight: choice.depth == 0 ? FontWeight.w600 : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (selected) Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The refreshed row: at least 48 high, indented by depth, the chosen
  /// screen on a tonal background with a primary tick.
  Widget _refreshed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = RefreshColors.card(context);
    final background = selected ? RefreshColors.tonal(context, on: card) : card;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: RefreshTokens.minTarget),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                RefreshTokens.cardPadding + choice.depth * CommunityTokens.screenIndent,
                10,
                12,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      choice.label(context),
                      // Top-level screens stand out from the screens under them.
                      style: RefreshTokens.body(context, weight: choice.depth == 0 ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: RefreshColors.readable(scheme.primary, scheme.onSurface, background, 3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
