import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import '../utils/formatters.dart';
import 'emoji_text.dart';

/// Type emoji used on cards and in the topic picker.
String feedbackTypeEmoji(FeedbackType type) {
  switch (type) {
    case FeedbackType.improvement:
      return '🛠️';
    case FeedbackType.problem:
      return '⚠️';
    case FeedbackType.idea:
      return '💡';
  }
}

/// One feedback item in a list: type, number, age, text, status, cost,
/// comment count and hearts. A Problem shows its screen path, description,
/// steps and device details instead of the text.
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({super.key, required this.item, this.now});

  final FeedbackItem item;

  /// For tests. Defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final onSurface = theme.colorScheme.onSurface;
    final muted = CommunityColors.muted(context);
    final costCents = item.costCents;
    final body = text.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: onSurface,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: CommunityColors.border(context)),
        borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
      ),
      child: Padding(
        padding: CommunityTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmojiText(feedbackTypeEmoji(item.type), size: 20),
                const SizedBox(width: 4),
                Text(
                  '#${item.number}',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w200,
                    color: onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  formatAge(l, item.createdAt, now: now),
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CommunityTokens.cardSectionGap),
            if (_hasProblemDetails(item))
              _ProblemDetails(item: item, style: body)
            else
              Text(item.text, style: body),
            const SizedBox(height: CommunityTokens.cardSectionGap),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: item.status == null ? null : _Status(status: item.status!),
                  ),
                ),
                if (costCents != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '💰', style: emojiStyle(16)),
                        TextSpan(text: ' ${formatUsd(l, costCents)}'),
                      ],
                    ),
                    style: text.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: CommunityColors.of(context).cost,
                    ),
                  ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Count(
                        emoji: '💬',
                        count: item.commentCount,
                        semanticsLabel: l.commentCount(item.commentCount),
                      ),
                      const SizedBox(width: 8),
                      _ReactionChip(item: item, semanticsLabel: l.reactionCount(item.reactionCount)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Problems posted with the Problem form have steps. Anything else shows
/// its text.
bool _hasProblemDetails(FeedbackItem item) =>
    item.type == FeedbackType.problem && (item.steps?.isNotEmpty ?? false);

/// 📲 path, the description, "1. … → 2. …" and the device line.
///
/// The steps are the card's main text, like an Improvement's. The optional
/// description is a step down in size, weight and colour, so the two do not
/// run together (Material type hierarchy:
/// https://m3.material.io/styles/typography/applying-type).
class _ProblemDetails extends StatelessWidget {
  const _ProblemDetails({required this.item, required this.style});

  final FeedbackItem item;
  final TextStyle? style;

  static const _lineGap = 4.0;
  static const _stepsGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final path = item.screenPath;
    final description = item.description;
    final steps = item.steps ?? const <String>[];
    final appVersion = item.appVersion;
    final device = [
      item.osVersion,
      if (appVersion != null) l.appVersionShort(appVersion),
      item.deviceModel,
    ].whereType<String>().join('  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (path != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '📲', style: emojiStyle(16)),
                TextSpan(text: ' ${formatScreenPath(path)}'),
              ],
            ),
            style: style,
          ),
          const SizedBox(height: _lineGap),
        ],
        if (description != null) ...[
          Text(
            description,
            style: style?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: _stepsGap),
        ],
        Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const TextSpan(text: ' → '),
                TextSpan(
                  text: '${i + 1}. ',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                TextSpan(text: steps[i]),
              ],
            ],
          ),
          style: style,
        ),
        if (device.isNotEmpty) ...[
          const SizedBox(height: _lineGap),
          Text(
            device,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: CommunityColors.muted(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});

  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final colors = CommunityColors.of(context);
    final (label, color) = switch (status) {
      FeedbackStatus.planned => (l.statusPlanned, colors.statusPlanned),
      FeedbackStatus.inProgress => (l.statusInProgress, colors.statusInProgress),
      FeedbackStatus.done => (l.statusDone, colors.statusDone),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EmojiText('💪', size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.emoji, required this.count, required this.semanticsLabel});

  final String emoji;
  final int count;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(emoji, size: 20),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Heart count in a small box. Red border when the user has reacted.
/// Read-only for now; tapping arrives with reactions.
class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.item, required this.semanticsLabel});

  final FeedbackItem item;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = item.reacted
        ? CommunityColors.of(context).reacted
        : CommunityColors.border(context);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(
          minWidth: CommunityTokens.reactionChipSize.width,
          minHeight: CommunityTokens.reactionChipSize.height,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '❤️', style: emojiStyle(16)),
              TextSpan(text: ' ${item.reactionCount}'),
            ],
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
