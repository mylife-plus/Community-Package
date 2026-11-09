import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../l10n/community_localizations.dart';
import '../navigation/community_screens.dart';
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
  const FeedbackCard({super.key, required this.item, this.onTap, this.onReact, this.now});

  /// Not in Figma: the least space between the cost and the counts.
  static const _costGap = 8.0;

  /// Not in Figma: the most of the bottom row the cost may take.
  static const _costMaxShare = 0.35;

  final FeedbackItem item;

  /// Tapping the card outside the heart, for example to open its detail.
  final VoidCallback? onTap;

  /// Tapping the heart. Null shows the hearts read-only.
  final VoidCallback? onReact;

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

    // A Material, not a DecoratedBox, so the tap ripple shows on the card.
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: CommunityColors.border(context)),
        borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // The heart's tap area reaches down to the card's edge instead.
          padding: CommunityTokens.cardPadding.copyWith(bottom: 0),
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
              SizedBox(height: CommunityTokens.cardSectionGap - _ReactionButton.tapPadding.top),
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    // Takes the free space, so the counts stay on the right.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: item.status == null ? null : _Status(status: item.status!),
                      ),
                    ),
                    // The cost keeps its size up to a share of the row; on
                    // a narrow card or with large text it ellipsizes, and
                    // the status gives way first.
                    if (costCents != null) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth * _costMaxShare),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '💰', style: emojiStyle(16)),
                              TextSpan(text: ' ${formatUsd(l, costCents)}'),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: CommunityColors.of(context).cost,
                          ),
                        ),
                      ),
                      const SizedBox(width: _costGap),
                    ],
                    _Count(
                      emoji: '💬',
                      count: item.commentCount,
                      semanticsLabel: l.commentCount(item.commentCount),
                    ),
                    _ReactionButton(item: item, onTap: onReact),
                  ],
                ),
              ),
            ],
          ),
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

    // Saved in English; shown in the app's language where the tree knows it.
    final screens = CommunityScreens.of(context);
    List<String> labels(List<String> names) => screenPathLabels(context, names, screens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (path != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '📲', style: emojiStyle(16)),
                TextSpan(text: ' ${formatScreenPath(path, labels: labels)}'),
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
    final label = feedbackStatusLabel(CommunityLocalizations.of(context), status);
    final color = CommunityColors.of(context).status(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EmojiText('💪', size: 16),
        const SizedBox(width: 4),
        // Shrinks on narrow phones instead of pushing into the counts.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: color,
            ),
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
///
/// The box keeps Figma's size; the tap area around it is larger (48 px
/// wide, as high as the card's spacing allows), so it is easy to hit.
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.item, required this.onTap});

  /// Space around the box that still takes taps. The left part is the gap
  /// to the comment count; top and bottom are the card's own spacing.
  static const tapPadding = EdgeInsets.fromLTRB(8, 7, 0, 6);

  static const _borderAnimation = Duration(milliseconds: 150);

  final FeedbackItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final border = item.reacted
        ? CommunityColors.of(context).reacted
        : CommunityColors.border(context);
    final onTap = this.onTap;
    return Semantics(
      label: l.reactionCount(item.reactionCount),
      hint: onTap == null ? null : (item.reacted ? l.removeHeart : l.addHeart),
      button: onTap != null,
      toggled: onTap == null ? null : item.reacted,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: tapPadding,
          child: AnimatedContainer(
            duration: _borderAnimation,
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
        ),
      ),
    );
  }
}
