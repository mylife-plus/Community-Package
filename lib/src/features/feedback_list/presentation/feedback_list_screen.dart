import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/state/loading_state.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_message.dart';
import '../../../core/widgets/controller_scope.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../core/widgets/feedback_card_skeleton.dart';
import 'feedback_list_controller.dart';

/// All Feedback: every post of the host app, newest first.
class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key, this.createController});

  /// For tests. Defaults to a controller on the registered repository.
  final FeedbackListController Function()? createController;

  /// Not tuned yet: how close to the end of the list the next page starts loading.
  static const loadMoreThreshold = 600.0;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return Scaffold(
      appBar: CommunityAppBar(emoji: '✍️', title: l.feedbackTitle),
      body: ControllerScope<FeedbackListController>(
        create:
            createController ??
            () => FeedbackListController(CommunityDependencies.feedbackRepository),
        builder: (controller) => _Body(controller: controller),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final FeedbackListController controller;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    switch (controller.state) {
      case LoadingState.idle:
      case LoadingState.loading:
        return ListView.separated(
          padding: _listPadding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: CommunityTokens.cardGap),
          itemBuilder: (_, _) => const FeedbackCardSkeleton(),
        );
      case LoadingState.error:
        return CommunityMessage(
          emoji: '📡',
          title: errorMessage(l, controller.error!),
          actionLabel: l.retry,
          onAction: controller.load,
        );
      case LoadingState.empty:
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: CommunityMessage(
                  emoji: '✍️',
                  title: l.emptyFeedbackTitle,
                  body: l.emptyFeedbackBody,
                ),
              ),
            ),
          ),
        );
      case LoadingState.success:
      case LoadingState.loadingMore:
        return _List(controller: controller, onRefresh: () => _refresh(context));
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = CommunityLocalizations.of(context);
    final error = await controller.refreshList();
    if (error != null) {
      messenger?.showSnackBar(SnackBar(content: Text(errorMessage(l, error))));
    }
  }
}

const _listPadding = EdgeInsets.fromLTRB(
  CommunityTokens.screenPadding,
  CommunityTokens.cardGap,
  CommunityTokens.screenPadding,
  CommunityTokens.cardGap * 3,
);

class _List extends StatelessWidget {
  const _List({required this.controller, required this.onRefresh});

  final FeedbackListController controller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    final showFooter = controller.state == LoadingState.loadingMore || controller.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < FeedbackListScreen.loadMoreThreshold &&
            controller.loadMoreError == null) {
          controller.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          padding: _listPadding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: CommunityTokens.cardGap),
          itemBuilder: (context, index) {
            if (index < items.length) {
              return FeedbackCard(key: ValueKey(items[index].number), item: items[index]);
            }
            if (controller.loadMoreError != null) return _LoadMoreError(controller: controller);
            return const FeedbackCardSkeleton();
          },
        ),
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.controller});

  final FeedbackListController controller;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            l.loadMoreFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CommunityColors.muted(context),
            ),
          ),
          TextButton(onPressed: controller.loadMore, child: Text(l.retry)),
        ],
      ),
    );
  }
}
