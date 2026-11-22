import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import '../utils/formatters.dart';
import 'community_menu.dart';
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
    if (CommunityRefresh.of(context)) {
      return _RefreshedPill(
        emoji: chosen == null ? null : feedbackTypeEmoji(chosen),
        label: chosen == null ? l.chooseTopic : feedbackTypeLabel(l, chosen),
        onTap: onTap,
      );
    }
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
    this.selected,
  });

  final List<FeedbackType> types;

  /// Ticked in the refreshed look.
  final FeedbackType? selected;
  final ValueChanged<FeedbackType> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    if (CommunityRefresh.of(context)) return _refreshed(context, l);
    final divider = Container(height: 1, color: Theme.of(context).colorScheme.primary);
    return _Frame(
      minWidth: CommunityTokens.topicMenuMinWidth,
      bottomRadius: CommunityTokens.topicMenuBottomRadius,
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

extension on FeedbackTypeMenu {
  /// The refreshed menu: the raised menu box (radius 12, a faint edge, a
  /// shadow), "Choose Topic" on top (tapping it closes the menu), then a
  /// 48 px row per type with a tick on the chosen one.
  Widget _refreshed(BuildContext context, CommunityLocalizations l) {
    return CommunityMenuFrame(
      children: [
        CommunityMenuRow(
          label: Text(l.chooseTopic, style: RefreshTokens.title(context)),
          centered: true,
          onTap: onClose,
        ),
        for (final type in types)
          CommunityMenuRow(
            emoji: feedbackTypeEmoji(type),
            label: Text(feedbackTypeLabel(l, type)),
            selected: type == selected,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

/// The refreshed closed picker: on the menu's raised colour, radius 12, a
/// faint edge, 48 high, the topic at the title size.
class _RefreshedPill extends StatelessWidget {
  const _RefreshedPill({this.emoji, required this.label, required this.onTap});

  final String? emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = this.emoji;
    final radius = BorderRadius.circular(RefreshTokens.controlRadius);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: CommunityTokens.topicPillMinWidth),
      child: Material(
        color: CommunityMenuFrame.background(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: RefreshColors.faintBorder(context))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: RefreshTokens.minTarget),
            padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null) ...[EmojiText(emoji, size: 20), const SizedBox(width: 8)],
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: RefreshTokens.title(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Black box with the blue outline shared by the pill and the menu.
class _Frame extends StatelessWidget {
  const _Frame({required this.minWidth, this.bottomRadius = CommunityTokens.topicRadius, required this.child});

  final double minWidth;

  /// Settings-1: the open menu's bottom corners are a little tighter.
  final double bottomRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.vertical(
      top: const Radius.circular(CommunityTokens.topicRadius),
      bottom: Radius.circular(bottomRadius),
    );
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
