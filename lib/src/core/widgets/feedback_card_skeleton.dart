import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';

/// Placeholder with the shape of a [FeedbackCard], shown while a list loads.
class FeedbackCardSkeleton extends StatefulWidget {
  const FeedbackCardSkeleton({super.key});

  @override
  State<FeedbackCardSkeleton> createState() => _FeedbackCardSkeletonState();
}

class _FeedbackCardSkeletonState extends State<FeedbackCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.06,
    upperBound: 0.14,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (CommunityRefresh.of(context)) return _refreshed(context);
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: CommunityColors.border(context)),
          borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
        ),
        child: Padding(
          padding: CommunityTokens.cardPadding,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final bar = theme.colorScheme.onSurface.withValues(alpha: _pulse.value);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Bar(color: bar, width: 44, height: 18),
                      const Spacer(),
                      _Bar(color: bar, width: 48, height: 14),
                    ],
                  ),
                  const SizedBox(height: CommunityTokens.cardSectionGap),
                  _Bar(color: bar, height: 16),
                  const SizedBox(height: 6),
                  _Bar(color: bar, width: 200, height: 16),
                  const SizedBox(height: CommunityTokens.cardSectionGap),
                  Row(
                    children: [
                      _Bar(color: bar, width: 90, height: 16),
                      const Spacer(),
                      _Bar(
                        color: bar,
                        width: CommunityTokens.reactionChipSize.width,
                        height: CommunityTokens.reactionChipSize.height,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The refreshed card's shape: card colour, radius 16, a faint edge, 16
  /// inside, the 48 high top row, two lines of text and the bottom row
  /// with the heart pill.
  Widget _refreshed(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RefreshColors.card(context),
          border: Border.all(color: RefreshColors.faintBorder(context)),
          borderRadius: BorderRadius.circular(RefreshTokens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RefreshTokens.cardPadding, 0, RefreshTokens.cardPadding, 12),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final bar = onSurface.withValues(alpha: _pulse.value);
              const radius = _refreshedBarRadius;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: RefreshTokens.minTarget,
                    child: Row(
                      children: [
                        _Bar(color: bar, width: 56, height: 16, radius: radius),
                        const Spacer(),
                        _Bar(color: bar, width: 40, height: 12, radius: radius),
                      ],
                    ),
                  ),
                  _Bar(color: bar, height: 14, radius: radius),
                  const SizedBox(height: 8),
                  _Bar(color: bar, width: 200, height: 14, radius: radius),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Bar(color: bar, width: 90, height: 16, radius: radius),
                      const Spacer(),
                      _Bar(color: bar, width: 40, height: 16, radius: radius),
                      const SizedBox(width: 8),
                      _Bar(color: bar, width: 64, height: 40, radius: 20),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static const _refreshedBarRadius = 6.0;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.height, this.width, this.radius = CommunityTokens.cardRadius});

  final Color color;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
