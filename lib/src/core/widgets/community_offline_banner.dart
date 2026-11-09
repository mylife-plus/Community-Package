import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';
import 'emoji_text.dart';

/// A thin bar under the app bar while saved data is shown without a
/// connection, with a button to try again. Collapses when [visible] is
/// false.
class CommunityOfflineBanner extends StatelessWidget {
  const CommunityOfflineBanner({
    super.key,
    required this.visible,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final bool visible;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  static const _minHeight = 40.0;

  /// The most of the bar's width the button may take.
  static const _actionMaxShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: _minHeight),
                color: scheme.surfaceContainerHighest,
                padding: const EdgeInsets.only(left: CommunityTokens.formPadding, right: 4),
                // The text wraps beside the button; a long button label
                // (or a large text size) wraps too instead of squeezing the
                // text.
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '📡 ', style: emojiStyle(16)),
                                TextSpan(text: message),
                              ],
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth * _actionMaxShare),
                        child: TextButton(
                          onPressed: onAction,
                          child: Text(actionLabel, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
