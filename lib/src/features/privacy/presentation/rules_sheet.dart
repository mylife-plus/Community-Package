import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/emoji_text.dart';
import '../../../core/widgets/refresh_buttons.dart';

/// The community rules. Agree closes the sheet with true; dragging it down
/// closes it with null. Once [agreed], it only has a close button.
class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key, this.agreed = false});

  final bool agreed;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final heading = RefreshTokens.title(context)?.copyWith(height: CommunityTokens.lineHeight);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(_side, 4, _side, _side),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmojiText('❌', size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l.rulesTitle, style: heading)),
              ],
            ),
            const SizedBox(height: 20),
            _Rule(emoji: '🪪', text: l.ruleNoPrivateInfo),
            const SizedBox(height: _ruleGap),
            _Rule(emoji: '🤌', text: l.ruleNoUnrelated),
            const SizedBox(height: _ruleGap),
            _Rule(emoji: '🤬', text: l.ruleNoHate),
            const SizedBox(height: RefreshTokens.sheetPadding),
            Text(
              l.rulesWarning,
              textAlign: TextAlign.center,
              style: heading?.copyWith(height: CommunityTokens.readingLineHeight),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(l.rulesThanks, style: heading)),
                const SizedBox(width: 6),
                EmojiText('😊', size: 18),
              ],
            ),
            const SizedBox(height: RefreshTokens.sheetPadding),
            agreed
                ? RefreshButton(
                    label: l.close,
                    kind: RefreshButtonKind.secondary,
                    onPressed: () => closePopup(context),
                  )
                : RefreshButton(label: l.agree, onPressed: () => closePopup(context, true)),
          ],
        ),
      ),
    );
  }

  static const _side = RefreshTokens.sheetPadding;
  static const _ruleGap = 8.0;
}

/// One rule: a card tinted red with a red edge, the text in the normal
/// text colour.
class _Rule extends StatelessWidget {
  const _Rule({required this.emoji, required this.text});

  final String emoji;
  final String text;

  static const _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sheet = RefreshColors.sheet(context);
    return Container(
      constraints: const BoxConstraints(minHeight: RefreshTokens.minTarget),
      padding: const EdgeInsets.symmetric(horizontal: RefreshTokens.cardPadding, vertical: 12),
      decoration: BoxDecoration(
        color: RefreshColors.errorTonal(context, on: sheet),
        border: Border.all(color: errorEdge(context), width: _borderWidth),
        borderRadius: BorderRadius.circular(RefreshTokens.controlRadius),
      ),
      child: Row(
        children: [
          EmojiText(emoji, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: RefreshTokens.body(context, weight: FontWeight.w600)?.copyWith(
                height: CommunityTokens.readingLineHeight,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The red edge, at 3:1 or more on the sheet so it reads as red
  /// (WCAG 1.4.11, non-text contrast).
  static Color errorEdge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshColors.readable(scheme.error, scheme.onSurface, RefreshColors.sheet(context), 3);
  }
}
