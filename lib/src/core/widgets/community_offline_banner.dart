import 'package:flutter/material.dart';

import '../theme/refresh_style.dart';
import 'emoji_text.dart';
import 'refresh_buttons.dart';

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

  static const _minHeight = RefreshTokens.minTarget;

  /// The most of the bar's width the button may take.
  static const _actionMaxShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The field layer: visible on every host, also where the scheme leaves
    // surfaceContainerHighest at the screen colour.
    final background = RefreshColors.field(context);
    final textColor = scheme.onSurface;
    final actionColor = RefreshColors.readable(scheme.primary, scheme.onSurface, background, 4.5);
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
                color: background,
                padding: const EdgeInsets.only(left: RefreshTokens.screenPadding, right: 4),
                // The text wraps beside the button; a long button label
                // (or a large text size) wraps too instead of squeezing the
                // text.
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '📡 ', style: emojiStyle(16)),
                                TextSpan(text: message),
                              ],
                            ),
                            style: RefreshTokens.meta(context, color: textColor, weight: FontWeight.w500)
                                ?.copyWith(fontSize: 14, height: 1.3),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth * _actionMaxShare),
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: actionColor,
                            minimumSize: const Size(RefreshTokens.minTarget, RefreshTokens.minTarget),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(RefreshTokens.controlRadius),
                            ),
                            textStyle: RefreshTokens.meta(context, weight: FontWeight.w600)?.copyWith(fontSize: 14),
                          ),
                          child: Text(sentenceCase(actionLabel), textAlign: TextAlign.center),
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
