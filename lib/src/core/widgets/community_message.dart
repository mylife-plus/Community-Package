import 'package:flutter/material.dart';

import '../theme/refresh_style.dart';
import 'emoji_text.dart';
import 'refresh_buttons.dart';

/// Centered emoji, title, text and an optional action (outlined, 48 high).
/// Used for empty and error states.
class CommunityMessage extends StatelessWidget {
  const CommunityMessage({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Keeps long lines readable on wide screens.
  static const _maxWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RefreshTokens.sheetPadding, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmojiText(emoji, size: 40),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: RefreshTokens.title(context)?.copyWith(height: 1.3),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: RefreshTokens.body(context, color: RefreshColors.meta(context, on: background)),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: RefreshTokens.sheetPadding),
                RefreshButton(label: actionLabel!, onPressed: onAction, kind: RefreshButtonKind.secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
