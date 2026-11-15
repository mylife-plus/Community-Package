import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/state/loading_state.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/comment_query_menus.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_list_toolbar.dart';
import '../../../core/widgets/community_message.dart';
import '../../../core/widgets/community_offline_banner.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/controller_scope.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../core/widgets/feedback_card_skeleton.dart';
import '../../../data/models/comment_query.dart';
import '../../../data/models/feedback_comment.dart';
import '../../../data/models/feedback_item.dart';
import '../../privacy/presentation/post_gate.dart';
import 'comment_field.dart';
import 'comment_thread.dart';
import 'edit_comment_sheet.dart';
import 'feedback_detail_controller.dart';

/// One feedback with its comments (Settings-6, 7 and 8): the card, the
/// comment toolbar (sort, filter, search, +), the new comment field and the
/// threads. The header shows the status, or the type while there is none.
/// Timeline, GitHub and the Admin label come with the admin tools (S10).
class FeedbackDetailScreen extends StatelessWidget {
  const FeedbackDetailScreen({super.key, required this.number, this.createController, this.postGate});

  /// The feedback's number.
  final int number;

  /// For tests. Defaults to a controller on the registered repositories.
  final FeedbackDetailController Function()? createController;

  /// For tests. Defaults to a gate on the registered identity repository.
  final PostGate? postGate;

  /// Not tuned yet: how close to the end the next page of comments loads.
  static const loadMoreThreshold = 600.0;

  /// Opacity of the old comments while another sort, filter or search loads.
  static const switchingOpacity = 0.5;

  PostGate get _gate =>
      postGate ??
      PostGate(
        identity: CommunityDependencies.identityRepository,
        privacyPolicyUrl: CommunityDependencies.config.privacyPolicyUrl,
      );

  @override
  Widget build(BuildContext context) {
    return ControllerScope<FeedbackDetailController>(
      create:
          createController ??
          () => FeedbackDetailController(
            number: number,
            feedback: CommunityDependencies.feedbackRepository,
            comments: CommunityDependencies.commentRepository,
          ),
      builder: (controller) => Scaffold(
        appBar: _appBar(context, controller.item),
        body: Column(
          children: [
            CommunityOfflineBanner(
              visible: controller.showOfflineBar,
              message: CommunityLocalizations.of(context).offlineShowingSaved,
              actionLabel: CommunityLocalizations.of(context).retry,
              onAction: () => _retry(context, controller),
            ),
            Expanded(
              child: _Body(
                controller: controller,
                onReact: () => _react(context, controller),
                onSendComment: () => _sendComment(context, controller),
                onSendReply: (thread) => _sendReply(context, controller, thread),
                onEdit: (comment) => _edit(context, controller, comment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The offline bar's button: reloads everything, like pull-to-refresh.
  Future<void> _retry(BuildContext context, FeedbackDetailController controller) async {
    final error = await controller.refreshAll();
    if (error != null && context.mounted) _showError(context, error);
  }

  /// Settings-6, -7: the header's emoji is 20, like the card's.
  static const _headerEmojiSize = 20.0;

  PreferredSizeWidget _appBar(BuildContext context, FeedbackItem? item) {
    final l = CommunityLocalizations.of(context);
    if (item == null) return CommunityAppBar(emoji: '✍️', title: l.feedbackTitle);
    final status = item.status;
    if (status != null) {
      return CommunityAppBar(
        emoji: '💪',
        emojiSize: _headerEmojiSize,
        title: feedbackStatusLabel(l, status),
        titleWeight: FontWeight.w500,
        titleColor: CommunityColors.of(context).status(status),
      );
    }
    return CommunityAppBar(
      emoji: feedbackTypeEmoji(item.type),
      emojiSize: _headerEmojiSize,
      title: feedbackTypeLabel(l, item.type),
    );
  }

  /// A heart needs the privacy notice once, not the rules.
  Future<void> _react(BuildContext context, FeedbackDetailController controller) async {
    if (!await _gate.ensureIdentity(context)) return;
    final error = await controller.toggleReaction();
    if (error == null || !context.mounted) return;
    final l = CommunityLocalizations.of(context);
    showCommunitySnackBar(
      context,
      error.type == AppErrorType.rateLimited ? l.errorTooManyHearts : errorMessage(l, error),
    );
  }

  /// Comments and replies need the privacy notice and the rules.
  Future<void> _sendComment(BuildContext context, FeedbackDetailController controller) async {
    if (!await _gate.ensureCanPost(context) || !context.mounted) return;
    final error = await runWithLoading(context, controller.sendComment);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _sendReply(BuildContext context, FeedbackDetailController controller, FeedbackComment thread) async {
    if (!await _gate.ensureCanPost(context) || !context.mounted) return;
    final error = await runWithLoading(context, () => controller.sendReply(thread));
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _edit(BuildContext context, FeedbackDetailController controller, FeedbackComment comment) async {
    final result = await showCommunitySheet<EditCommentResult>(
      context,
      barrierColor: CommunityTokens.sheetScrim,
      builder: (_) => EditCommentSheet(comment: comment, maxLength: FeedbackDetailController.maxCommentLength),
    );
    if (result == null || !context.mounted) return;
    try {
      await runWithLoading(context, () async {
        switch (result) {
          case SaveCommentEdit(:final text):
            await controller.editComment(comment, text);
          case DeleteCommentEdit():
            await controller.deleteComment(comment);
        }
      });
    } on AppError catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
      // Someone (or the admin) removed it meanwhile: show the list as it is.
      if (e.type == AppErrorType.notFound) controller.refreshAll();
    }
  }

  static void _showError(BuildContext context, AppError error) {
    final l = CommunityLocalizations.of(context);
    final message = switch (error.type) {
      AppErrorType.rateLimited => l.errorTooManyComments,
      AppErrorType.notFound => l.commentNotFound,
      _ => errorMessage(l, error),
    };
    showCommunitySnackBar(context, message);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.onReact,
    required this.onSendComment,
    required this.onSendReply,
    required this.onEdit,
  });

  final FeedbackDetailController controller;
  final VoidCallback onReact;
  final VoidCallback onSendComment;
  final ValueChanged<FeedbackComment> onSendReply;
  final ValueChanged<FeedbackComment> onEdit;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final item = controller.item;
    if (item == null) {
      final error = controller.itemError;
      if (controller.itemState == LoadingState.error && error != null) {
        if (error.type == AppErrorType.notFound) {
          return CommunityMessage(emoji: '🗑️', title: l.feedbackNotFound);
        }
        return CommunityMessage(
          emoji: '📡',
          title: errorMessage(l, error),
          actionLabel: l.retry,
          onAction: () {
            controller.loadItem();
            controller.loadComments();
          },
        );
      }
      return ListView.separated(
        padding: _padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: CommunityTokens.cardGap),
        itemBuilder: (_, _) => const FeedbackCardSkeleton(),
      );
    }

    final query = controller.query;
    final children = <Widget>[
      FeedbackCard(item: item, onReact: onReact),
      CommunityListToolbar(
        sortActive: query.sort != CommentSort.newest,
        filterActive: query.hasFilter,
        onSort: (anchor) => showCommentSortMenu(anchor, selected: query.sort, onSelected: controller.setSort),
        onFilter: (anchor) => showCommentFilterMenu(
          anchor,
          filters: query.filters,
          onToggle: controller.toggleFilter,
          onReset: controller.resetFilter,
        ),
        searchOpen: controller.searchOpen,
        searchController: controller.searchController,
        searchHint: l.searchCommentsHint,
        maxSearchLength: FeedbackDetailController.maxSearchLength,
        onOpenSearch: controller.openSearch,
        onCloseSearch: controller.closeSearch,
        onSearchChanged: controller.onSearchChanged,
        onSearchSubmitted: controller.searchNow,
        onAdd: controller.toggleNewComment,
        addTooltip: l.writeComment,
        addActive: controller.newCommentOpen,
        addColor: CommunityColors.commentAdd(context),
      ),
      if (controller.newCommentOpen && !controller.searchOpen)
        CommentField(
          controller: controller.newCommentController,
          sending: controller.isSending(FeedbackDetailController.newCommentKey),
          onSend: onSendComment,
          maxLength: FeedbackDetailController.maxCommentLength,
          large: true,
          autofocus: true,
        ),
      ..._comments(context),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < FeedbackDetailScreen.loadMoreThreshold &&
            controller.loadMoreError == null) {
          controller.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView.separated(
          padding: _padding,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: children.length,
          // Settings-6: the comments start 66 under the card (the toolbar
          // is 46); threads keep the list's gap.
          separatorBuilder: (_, index) => SizedBox(
            height: switch (index) {
              0 => CommunityTokens.detailCardToToolbar,
              1 => CommunityTokens.detailToolbarToComments,
              _ => CommunityTokens.cardGap,
            },
          ),
          itemBuilder: (_, index) => children[index],
        ),
      ),
    );
  }

  List<Widget> _comments(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    switch (controller.commentsState) {
      case LoadingState.idle:
      case LoadingState.loading:
        if (controller.isSwitching) {
          return [
            for (final thread in controller.comments)
              AnimatedOpacity(
                opacity: FeedbackDetailScreen.switchingOpacity,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(child: _thread(thread)),
              ),
          ];
        }
        return const [FeedbackCardSkeleton(), FeedbackCardSkeleton()];
      case LoadingState.error:
        return [
          CommunityMessage(
            emoji: '📡',
            title: errorMessage(l, controller.commentsError!),
            actionLabel: l.retry,
            onAction: controller.loadComments,
          ),
        ];
      case LoadingState.empty:
        return [
          if (controller.query.narrows)
            CommunityMessage(
              emoji: '🔍',
              title: l.noMatchesTitle,
              body: l.noMatchesBody,
              actionLabel: l.clearSearchAndFilter,
              onAction: controller.clearSearchAndFilter,
            )
          else
            CommunityMessage(emoji: '💬', title: l.noCommentsTitle, body: l.noCommentsBody),
        ];
      case LoadingState.success:
      case LoadingState.loadingMore:
        return [
          for (final thread in controller.comments) _thread(thread),
          if (controller.loadMoreError != null)
            _LoadMoreError(onRetry: controller.loadMore)
          else if (controller.commentsState == LoadingState.loadingMore)
            const FeedbackCardSkeleton(),
        ];
    }
  }

  Widget _thread(FeedbackComment thread) => CommentThread(
    key: ValueKey(thread.id),
    thread: thread,
    open: controller.isOpen(thread),
    onToggle: () => controller.toggleThread(thread),
    onEdit: onEdit,
    replyController: controller.replyController(thread),
    replying: controller.isReplying(thread),
    onReply: () => controller.openReply(thread),
    onLeaveReply: () => controller.closeReply(thread),
    sendingReply: controller.isSending(thread.id),
    onSendReply: () => onSendReply(thread),
    maxLength: FeedbackDetailController.maxCommentLength,
  );

  Future<void> _refresh(BuildContext context) async {
    final error = await controller.refreshAll();
    if (error != null && context.mounted) {
      showCommunitySnackBar(context, errorMessage(CommunityLocalizations.of(context), error));
    }
  }
}

// Settings-6: the card's top is 27 below the title's centre.
const _padding = EdgeInsets.fromLTRB(
  CommunityTokens.screenPadding,
  5,
  CommunityTokens.screenPadding,
  CommunityTokens.cardGap * 3,
);

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return Column(
      children: [
        Text(
          l.loadMoreCommentsFailed,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CommunityColors.muted(context)),
        ),
        TextButton(onPressed: onRetry, child: Text(l.retry)),
      ],
    );
  }
}
