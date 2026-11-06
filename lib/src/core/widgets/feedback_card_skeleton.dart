import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';

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
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.height, this.width});

  final Color color;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(CommunityTokens.cardRadius),
    ),
  );
}
