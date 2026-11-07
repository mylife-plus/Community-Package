import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/state/loading_state.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_message.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/controller_scope.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../core/widgets/feedback_card_skeleton.dart';
import '../../../core/widgets/feedback_list_toolbar.dart';
import '../../../data/models/feedback_item.dart';
import '../../privacy/presentation/post_gate.dart';
import 'feedback_list_controller.dart';

/// All Feedback: every post of the host app, newest first, with sort,
/// filter, search and hearts.
class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key, this.createController, this.postGate});

  /// For tests. Defaults to a controller on the registered repository.
  final FeedbackListController Function()? createController;

  /// For tests. Defaults to a gate on the registered identity repository.
  final PostGate? postGate;

  /// Not tuned yet: how close to the end of the list the next page starts loading.
  static const loadMoreThreshold = 600.0;

  /// Opacity of the old list while another sort, filter or search loads.
  static const switchingOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return Scaffold(
      appBar: CommunityAppBar(emoji: '✍️', title: l.feedbackTitle),
      body: ControllerScope<FeedbackListController>(
        create:
            createController ??
            () => FeedbackListController(CommunityDependencies.feedbackRepository),
        builder: (controller) => Column(
          children: [
            FeedbackListToolbar(
              query: controller.query,
              searchOpen: controller.searchOpen,
              searchController: controller.searchController,
              maxSearchLength: FeedbackListController.maxSearchLength,
              onSort: controller.setSort,
              onToggleType: controller.toggleType,
              onToggleStatus: controller.toggleStatus,
              onResetFilter: controller.resetFilter,
              onOpenSearch: controller.openSearch,
              onCloseSearch: controller.closeSearch,
              onSearchChanged: controller.onSearchChanged,
              onSearchSubmitted: controller.searchNow,
              onAdd: () => CommunityNavigator.openNewFeedback(context),
              addTooltip: l.newFeedbackTitle,
            ),
            Expanded(
              child: _Body(controller: controller, onReact: (item) => _react(context, controller, item)),
            ),
          ],
        ),
      ),
    );
  }

  /// A heart needs the privacy notice once, not the rules.
  Future<void> _react(BuildContext context, FeedbackListController controller, FeedbackItem item) async {
    final gate =
        postGate ??
        PostGate(
          identity: CommunityDependencies.identityRepository,
          privacyPolicyUrl: CommunityDependencies.config.privacyPolicyUrl,
        );
    if (!await gate.ensureIdentity(context)) return;
    final error = await controller.toggleReaction(item);
    if (error == null || !context.mounted) return;
    final l = CommunityLocalizations.of(context);
    showCommunitySnackBar(
      context,
      error.type == AppErrorType.rateLimited ? l.errorTooManyHearts : errorMessage(l, error),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.onReact});

  final FeedbackListController controller;
  final ValueChanged<FeedbackItem> onReact;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    switch (controller.state) {
      case LoadingState.idle:
      case LoadingState.loading:
        // Another query is loading: the old list stays, dimmed.
        if (controller.isSwitching) {
          return AnimatedOpacity(
            opacity: FeedbackListScreen.switchingOpacity,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              child: _List(controller: controller, onRefresh: () => _refresh(context), onReact: onReact),
            ),
          );
        }
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
        // Nothing at all yet, or nothing that matches the search or filter.
        final searched = controller.query.search.isNotEmpty || controller.query.hasFilter;
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: searched
                    ? CommunityMessage(
                        emoji: '🔍',
                        title: l.noMatchesTitle,
                        body: l.noMatchesBody,
                        actionLabel: l.clearSearchAndFilter,
                        onAction: controller.clearSearchAndFilter,
                      )
                    : CommunityMessage(
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
        return _List(controller: controller, onRefresh: () => _refresh(context), onReact: onReact);
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final error = await controller.refreshList();
    if (error != null && context.mounted) {
      showCommunitySnackBar(context, errorMessage(CommunityLocalizations.of(context), error));
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
  const _List({required this.controller, required this.onRefresh, required this.onReact});

  final FeedbackListController controller;
  final Future<void> Function() onRefresh;
  final ValueChanged<FeedbackItem> onReact;

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
              final item = items[index];
              return FeedbackCard(key: ValueKey(item.number), item: item, onReact: () => onReact(item));
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
