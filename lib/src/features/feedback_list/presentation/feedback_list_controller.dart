import 'dart:async';

import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/state/loading_state.dart';
import '../../../data/models/feedback_item.dart';
import '../../../data/repositories/feedback_repository.dart';

/// State of the All Feedback list. Data arrives through the repository stream.
class FeedbackListController extends GetxController {
  FeedbackListController(this._repository);

  final FeedbackRepository _repository;
  StreamSubscription<FeedbackPage>? _subscription;
  bool _closed = false;

  LoadingState state = LoadingState.idle;
  List<FeedbackItem> items = const [];
  bool hasMore = false;

  /// Why the first load failed, while there is nothing to show.
  AppError? error;

  /// Why the last "load more" failed. Shown under the list with a retry.
  AppError? loadMoreError;

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.feedbackListStream.listen(_onList);
    load();
  }

  @override
  void onClose() {
    _closed = true;
    _subscription?.cancel();
    super.onClose();
  }

  /// First load, and the retry after an error.
  Future<void> load() async {
    if (items.isEmpty) {
      state = LoadingState.loading;
      error = null;
      update();
    }
    try {
      await _repository.getFeedbackList();
    } on AppError catch (e) {
      if (_closed || items.isNotEmpty) return;
      error = e;
      state = LoadingState.error;
      update();
    }
  }

  /// Pull-to-refresh. Returns the error to tell the user about, if any; the
  /// list on screen stays as it was.
  Future<AppError?> refreshList() async {
    try {
      await _repository.getFeedbackList(forceRefresh: true);
      return null;
    } on AppError catch (e) {
      return e;
    }
  }

  /// Infinite scroll, and the retry after a failed page: loads the next page
  /// when there is one.
  Future<void> loadMore() async {
    if (!hasMore || state != LoadingState.success) return;
    state = LoadingState.loadingMore;
    loadMoreError = null;
    update();
    try {
      await _repository.loadMore();
    } on AppError catch (e) {
      loadMoreError = e;
    }
    if (_closed) return;
    if (state == LoadingState.loadingMore) state = LoadingState.success;
    update();
  }

  void _onList(FeedbackPage page) {
    if (_closed) return;
    items = page.items;
    hasMore = page.nextCursor != null;
    error = null;
    state = items.isEmpty ? LoadingState.empty : LoadingState.success;
    update();
  }
}
