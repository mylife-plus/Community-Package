import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';

/// The filled buttons of the sheets: agree, decline, close.
class CommunityButton extends StatelessWidget {
  const CommunityButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Red, for decline. Otherwise the theme's primary colour.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: destructive ? scheme.error : scheme.primary,
        foregroundColor: destructive ? scheme.onError : scheme.onPrimary,
        minimumSize: CommunityTokens.buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CommunityTokens.buttonRadius),
        ),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
