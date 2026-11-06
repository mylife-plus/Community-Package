import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/widgets/community_button.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/emoji_text.dart';

/// The community rules. Agree closes the sheet with true; dragging it down
/// closes it with null. Once [agreed], it only has a close button.
class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key, this.agreed = false});

  final bool agreed;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final heading = theme.textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: onSurface,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(9, 20, 9, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmojiText('❌', size: 18),
              const SizedBox(width: 8),
              Text(l.rulesTitle, style: heading),
            ],
          ),
          const SizedBox(height: 20),
          _Rule(emoji: '🪪', text: l.ruleNoPrivateInfo),
          const SizedBox(height: 3),
          _Rule(emoji: '🤌', text: l.ruleNoUnrelated),
          const SizedBox(height: 3),
          _Rule(emoji: '🤬', text: l.ruleNoHate),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                Text(l.rulesWarning, textAlign: TextAlign.center, style: heading),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.rulesThanks, style: heading),
                    const SizedBox(width: 6),
                    EmojiText('😊', size: 18),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: agreed
                ? CommunityButton(label: l.close, onPressed: () => closePopup(context))
                : CommunityButton(label: l.agree, onPressed: () => closePopup(context, true)),
          ),
        ],
      ),
    );
  }
}

/// One rule: white text on a red row.
class _Rule extends StatelessWidget {
  const _Rule({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: CommunityTokens.rowHeight),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(CommunityTokens.rowRadius),
      ),
      child: Row(
        children: [
          EmojiText(emoji, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
