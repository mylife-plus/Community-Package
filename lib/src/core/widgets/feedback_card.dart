import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../l10n/community_localizations.dart';
import '../navigation/community_screens.dart';
import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import '../utils/formatters.dart';
import 'emoji_text.dart';
import 'inner_shadow.dart';

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

  /// Settings-15: the type emoji sits 5 from the card's edge; the text and
  /// the bottom row 7 further in (12).
  static const _emojiInset = 5.0;
  static const _contentInset = 7.0;

  /// Settings-15: "#2" 4 lower than the emoji's top; the text 41 below the
  /// card's top (the 25 px emoji line, then 10); the heart chip 9 under the
  /// text.
  static const _numberTop = 4.0;
  static const _headerGap = 10.0;
  static const _textToChip = 9.0;

  /// Settings-15: the age ends 13 before the card's right edge; the heart
  /// chip below it 8.
  static const _ageRightInset = 13.0;

  final FeedbackItem item;

  /// Tapping the card outside the heart, for example to open its detail.
  final VoidCallback? onTap;

  /// Tapping the heart. Null shows the hearts read-only.
  final VoidCallback? onReact;

  /// For tests. Defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (CommunityRefresh.of(context)) return _refreshed(context);
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final onSurface = theme.colorScheme.onSurface;
    final muted = CommunityColors.muted(context);
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
          padding: CommunityTokens.cardPadding.copyWith(left: _emojiInset, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings-15: the parts hang from the top, not centred.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmojiText(feedbackTypeEmoji(item.type), size: 20),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: _numberTop),
                    child: Text(
                      '#${item.number}',
                      style: text.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        color: onSurface,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: _ageRightInset - CommunityTokens.cardPadding.right),
                    child: Text(
                      formatAge(l, item.createdAt, now: now),
                      style: text.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _headerGap),
              Padding(
                padding: const EdgeInsets.only(left: _contentInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasProblemDetails(item))
                      _ProblemDetails(item: item, style: body)
                    else
                      Text(item.text, style: body),
                    SizedBox(height: _textToChip - _ReactionButton.tapPadding.top),
                    LayoutBuilder(builder: (context, constraints) => _bottomRow(context, constraints)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The refreshed card: surfaceContainerLow, radius 16, a faint edge,
  /// 16 inside. The top row is 48 high, the same as on cards with an edit
  /// button.
  Widget _refreshed(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final card = RefreshColors.card(context);
    final body = RefreshTokens.body(context);
    final meta = RefreshTokens.meta(context, on: card);
    return Material(
      color: card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: RefreshColors.faintBorder(context)),
        borderRadius: BorderRadius.circular(RefreshTokens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RefreshTokens.cardPadding, 0, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: RefreshTokens.minTarget,
                child: Row(
                  children: [
                    EmojiText(feedbackTypeEmoji(item.type), size: 20),
                    const SizedBox(width: 8),
                    Text('#${item.number}', style: meta?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(formatAge(l, item.createdAt, now: now), style: meta),
                    const SizedBox(width: RefreshTokens.cardPadding - 4),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: RefreshTokens.cardPadding - 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasProblemDetails(item)) _ProblemDetails(item: item, style: body) else Text(item.text, style: body),
                    const SizedBox(height: 4),
                    _refreshedBottomRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _refreshedBottomRow(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final card = RefreshColors.card(context);
    final scheme = Theme.of(context).colorScheme;
    final costCents = item.costCents;
    final status = item.status;
    // Every part (status, cost, 💬 count, ❤️ pill) sits on one text
    // baseline; centring them one by one left the heart's number lower.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Status and cost together on the left (Johannes, 22 Nov); the
        // counts stay at the right edge. Both shrink with "…" when the row
        // is short, so the counts always fit.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (status != null) Flexible(child: _Status(status: status)),
              if (costCents != null) ...[
                if (status != null) const SizedBox(width: _refreshedCostGap),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '💰', style: emojiStyle(RefreshTokens.countEmojiSize)),
                        TextSpan(text: ' ${formatUsd(l, costCents)}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RefreshTokens.meta(
                      context,
                      color: RefreshColors.readable(CommunityColors.of(context).cost, scheme.onSurface, card, 4.5),
                      weight: FontWeight.w600,
                    )?.copyWith(fontSize: RefreshTokens.countTextSize),
                  ),
                ),
              ],
              const SizedBox(width: _refreshedCostGap),
            ],
          ),
        ),
        _Count(emoji: '💬', count: item.commentCount, semanticsLabel: l.commentCount(item.commentCount)),
        const SizedBox(width: _refreshedHeartGap),
        _ReactionButton(item: item, onTap: onReact),
      ],
    );
  }

  static const _refreshedCostGap = 12.0;
  static const _refreshedHeartGap = 8.0;

  Widget _bottomRow(BuildContext context, BoxConstraints constraints) {
    final l = CommunityLocalizations.of(context);
    final costCents = item.costCents;
    return Row(
      children: [
        // Takes the free space, so the counts stay on the right. Centred on
        // the heart chip, which sits lower in its tap area (Settings-15).
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: _ReactionButton.chipCentreShift),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: item.status == null ? null : _Status(status: item.status!),
                  ),
                ),
                // The cost keeps its size up to a share of the row; on a
                // narrow card or with large text it ellipsizes, and the
                // status gives way first.
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
              ],
            ),
          ),
        ),
        _ReactionButton(item: item, onTap: onReact),
      ],
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

  /// Settings-8: the steps start 31.5 below the path's line, the device
  /// line 29 below the steps' last line.
  static const _pathGap = 11.5;
  static const _deviceGap = 9.0;
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
          const SizedBox(height: _pathGap),
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
          const SizedBox(height: _deviceGap),
          Text(
            device,
            style: style?.copyWith(color: CommunityColors.deviceLine(context)),
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
    // On a narrow card with a long cost, many comments and the new-status
    // dot, not even 💪 fits: the status gives way instead of overflowing.
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < _emojiSize(context) + _gap
          ? const SizedBox.shrink()
          : _row(context, label, color),
    );
  }

  /// Settings-15: the label starts 22 after 💪's start.
  static const _gap = 6.0;

  /// 💪: 16, or the count size in the refreshed look. With the gap before
  /// the label, the least width the status needs.
  static double _emojiSize(BuildContext context) =>
      CommunityRefresh.of(context) ? RefreshTokens.countEmojiSize : 16;

  Widget _row(BuildContext context, String label, Color color) {
    final refreshed = CommunityRefresh.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: refreshed ? CrossAxisAlignment.baseline : CrossAxisAlignment.center,
      textBaseline: refreshed ? TextBaseline.alphabetic : null,
      children: [
        EmojiText('💪', size: _emojiSize(context)),
        const SizedBox(width: _gap),
        // Shrinks on narrow phones instead of pushing into the counts.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CommunityRefresh.of(context)
                ? RefreshTokens.meta(
                    context,
                    color: RefreshColors.readable(
                      color,
                      Theme.of(context).colorScheme.onSurface,
                      RefreshColors.card(context),
                      4.5,
                    ),
                    weight: FontWeight.w600,
                  )?.copyWith(fontSize: RefreshTokens.countTextSize)
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  /// Between the emoji and the number in the refreshed look.
  static const refreshedGap = 6.0;

  final String emoji;
  final int count;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refreshed = CommunityRefresh.of(context);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: refreshed ? CrossAxisAlignment.baseline : CrossAxisAlignment.center,
        textBaseline: refreshed ? TextBaseline.alphabetic : null,
        children: [
          EmojiText(emoji, size: refreshed ? RefreshTokens.countEmojiSize : 20),
          SizedBox(width: refreshed ? refreshedGap : 4),
          Text(
            '$count',
            style: refreshed
                ? RefreshTokens.meta(context, color: theme.colorScheme.onSurface, weight: FontWeight.w600)
                      ?.copyWith(fontSize: RefreshTokens.countTextSize)
                : theme.textTheme.bodyLarge?.copyWith(
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

/// Heart count in a small box with Figma's inner shadow. A red border
/// outside it when the user has reacted (Settings-15: 42×28 with it).
///
/// The box keeps Figma's size; the tap area around it is larger (48 px
/// wide, as high as the card's spacing allows), so it is easy to hit.
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.item, required this.onTap});

  /// Space around the box that still takes taps. The left part is the gap
  /// to the comment count; top and bottom are the card's own spacing.
  /// 9 is the whole gap between the text and the chip, so the tap area is
  /// 48 × 40 without moving the chip.
  static const _tapTop = 9.0;
  static const _tapBottom = 5.0;
  static const tapPadding = EdgeInsets.fromLTRB(8, _tapTop, 0, _tapBottom);

  /// How far the chip's centre is below its tap area's centre.
  static const chipCentreShift = _tapTop - _tapBottom;

  static const _borderAnimation = Duration(milliseconds: 150);

  final FeedbackItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final reacted = CommunityColors.of(context).reacted;
    // Transparent rather than none, so the border fades in and out.
    final border = item.reacted ? reacted : reacted.withValues(alpha: 0);
    final onTap = this.onTap;
    return Semantics(
      label: l.reactionCount(item.reactionCount),
      hint: onTap == null ? null : (item.reacted ? l.removeHeart : l.addHeart),
      button: onTap != null,
      toggled: onTap == null ? null : item.reacted,
      onTap: onTap,
      excludeSemantics: true,
      child: CommunityRefresh.of(context)
          ? _refreshedPill(context, border)
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: tapPadding,
                child: AnimatedContainer(
                  duration: _borderAnimation,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: border, strokeAlign: BorderSide.strokeAlignOutside),
                    borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
                  ),
                  child: InnerShadow(
                    radius: CommunityTokens.cardRadius,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: CommunityTokens.reactionChipSize.width,
                        minHeight: CommunityTokens.reactionChipSize.height,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
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
              ),
            ),
    );
  }

  static const _refreshedPillPadding = 14.0;
  static const _refreshedBorderWidth = 1.5;

  /// The refreshed heart: a 40 high tonal pill with a 48 tap area; when
  /// hearted, a border in the heart colour fades in.
  Widget _refreshedPill(BuildContext context, Color border) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedContainer(
          duration: _borderAnimation,
          height: 40,
          decoration: ShapeDecoration(
            color: RefreshColors.tonal(context),
            shape: StadiumBorder(side: BorderSide(color: border, width: _refreshedBorderWidth)),
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _refreshedPillPadding),
                child: Center(
                  widthFactor: 1,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '❤️', style: emojiStyle(RefreshTokens.countEmojiSize)),
                        TextSpan(text: ' ${item.reactionCount}'),
                      ],
                    ),
                    style: RefreshTokens.meta(context, color: scheme.onSurface, weight: FontWeight.w600)
                        ?.copyWith(fontSize: RefreshTokens.countTextSize),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
