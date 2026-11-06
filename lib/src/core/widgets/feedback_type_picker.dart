import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import '../utils/formatters.dart';
import 'emoji_text.dart';
import 'feedback_card.dart';

/// The closed topic picker: the chosen topic, or "Choose Topic" before one
/// is chosen. Tapping it opens [FeedbackTypeMenu].
class FeedbackTypePill extends StatelessWidget {
  const FeedbackTypePill({super.key, required this.type, required this.onTap});

  final FeedbackType? type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final chosen = type;
    return _Frame(
      minWidth: CommunityTokens.topicPillMinWidth,
      child: _Row(
        emoji: chosen == null ? null : feedbackTypeEmoji(chosen),
        label: chosen == null ? l.chooseTopic : feedbackTypeLabel(l, chosen),
        onTap: onTap,
      ),
    );
  }
}

/// The open topic picker: a "Choose Topic" title row, then one row per type.
/// Tapping the title closes it without a change.
class FeedbackTypeMenu extends StatelessWidget {
  const FeedbackTypeMenu({
    super.key,
    required this.types,
    required this.onSelected,
    required this.onClose,
  });

  final List<FeedbackType> types;
  final ValueChanged<FeedbackType> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final divider = Container(height: 1, color: Theme.of(context).colorScheme.primary);
    return _Frame(
      minWidth: CommunityTokens.topicMenuMinWidth,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row(label: l.chooseTopic, onTap: onClose),
            for (final type in types) ...[
              divider,
              _Row(
                emoji: feedbackTypeEmoji(type),
                label: feedbackTypeLabel(l, type),
                onTap: () => onSelected(type),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Black box with the blue outline shared by the pill and the menu.
class _Frame extends StatelessWidget {
  const _Frame({required this.minWidth, required this.child});

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(CommunityTokens.topicRadius);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.primary)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({this.emoji, required this.label, required this.onTap});

  final String? emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = this.emoji;
    return InkWell(
      onTap: onTap,
      // No alignment here: it would stretch the closed pill to full width.
      child: Container(
        height: CommunityTokens.topicRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null) ...[EmojiText(emoji, size: 18), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }
}
