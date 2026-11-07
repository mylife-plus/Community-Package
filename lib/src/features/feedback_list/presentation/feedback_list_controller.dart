import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/state/loading_state.dart';
import '../../../data/models/feedback_item.dart';
import '../../../data/models/feedback_query.dart';
import '../../../data/repositories/feedback_repository.dart';

/// State of the All Feedback list and its toolbar. Data arrives through the
/// repository stream.
class FeedbackListController extends GetxController {
  FeedbackListController(this._repository);

  /// Not tuned yet: the pause in typing before a search runs.
  static const searchDelay = Duration(milliseconds: 400);

  /// Longest search text; the backend allows the same.
  static const maxSearchLength = 100;

  final FeedbackRepository _repository;
  StreamSubscription<FeedbackList>? _listSubscription;
  StreamSubscription<FeedbackItem>? _createdSubscription;
  Timer? _searchTimer;
  bool _closed = false;

  /// While the list changes to another query with the old one still on
  /// screen, the state is [LoadingState.loading] and [items] are the old
  /// list's: the screen dims them (see [isSwitching]).
  LoadingState state = LoadingState.idle;
  List<FeedbackItem> items = const [];
  bool hasMore = false;

  /// The sort, filters and search the list shows (or is loading).
  FeedbackQuery query = const FeedbackQuery();

  /// The query [items] belong to.
  FeedbackQuery? _shownQuery;

  /// The toolbar shows the search field instead of its buttons.
  bool searchOpen = false;
  final searchController = TextEditingController();

  /// Why the first load failed, while there is nothing to show.
  AppError? error;

  /// Why the last "load more" failed. Shown under the list with a retry.
  AppError? loadMoreError;

  /// True while another query loads with the previous list still on screen.
  bool get isSwitching => state == LoadingState.loading && items.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _listSubscription = _repository.feedbackListStream.listen(_onList);
    _createdSubscription = _repository.createdStream.listen(_onCreated);
    load();
  }

  @override
  void onClose() {
    _closed = true;
    _searchTimer?.cancel();
    _listSubscription?.cancel();
    _createdSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }

  /// First load, a change of query, and the retry after an error.
  Future<void> load() async {
    final requested = query;
    if (_shownQuery != requested || items.isEmpty) {
      state = LoadingState.loading;
      error = null;
      loadMoreError = null;
      update();
    }
    try {
      await _repository.getFeedbackList(query: requested);
    } on AppError catch (e) {
      if (_closed || query != requested) return;
      if (_shownQuery == requested && items.isNotEmpty) return;
      items = const [];
      _shownQuery = null;
      error = e;
      state = LoadingState.error;
      update();
    }
  }

  /// Pull-to-refresh. Returns the error to tell the user about, if any; the
  /// list on screen stays as it was.
  Future<AppError?> refreshList() async {
    try {
      await _repository.getFeedbackList(query: query, forceRefresh: true);
      return null;
    } on AppError catch (e) {
      return e;
    }
  }

  /// Infinite scroll, and the retry after a failed page: loads the next page
  /// when there is one.
  Future<void> loadMore() async {
    if (!hasMore || state != LoadingState.success) return;
    final requested = query;
    state = LoadingState.loadingMore;
    loadMoreError = null;
    update();
    try {
      await _repository.loadMore(query: requested);
    } on AppError catch (e) {
      if (query == requested) loadMoreError = e;
    }
    if (_closed) return;
    if (state == LoadingState.loadingMore) state = LoadingState.success;
    update();
  }

  void setSort(FeedbackSort sort) => _show(query.copyWith(sort: sort));

  void toggleType(FeedbackType type) => _show(
    query.copyWith(types: _toggled(query.types, type)),
  );

  void toggleStatus(FeedbackStatus status) => _show(
    query.copyWith(statuses: _toggled(query.statuses, status)),
  );

  void resetFilter() => _show(query.copyWith(types: const {}, statuses: const {}));

  void openSearch() {
    if (searchOpen) return;
    searchOpen = true;
    update();
  }

  /// The ✗ of the search field: closes it and shows the list without a search.
  void closeSearch() {
    _searchTimer?.cancel();
    searchController.clear();
    searchOpen = false;
    update();
    _show(query.copyWith(search: ''));
  }

  /// Typing in the search field: searches once typing pauses.
  void onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, searchNow);
  }

  /// The keyboard's search key, and the end of a typing pause.
  void searchNow() {
    _searchTimer?.cancel();
    if (_closed) return;
    _show(query.copyWith(search: searchController.text.trim()));
  }

  /// The "clear" button when nothing matches: no search, no filter.
  void clearSearchAndFilter() {
    _searchTimer?.cancel();
    searchController.clear();
    searchOpen = false;
    _show(query.copyWith(search: '', types: const {}, statuses: const {}));
    update();
  }

  /// Hearts [item] or takes the heart back. Returns the error to tell the
  /// user about, if any; the heart is back as it was by then.
  Future<AppError?> toggleReaction(FeedbackItem item) async {
    try {
      await _repository.setReaction(item, on: !item.reacted);
      return null;
    } on AppError catch (e) {
      return e;
    }
  }

  void _show(FeedbackQuery next) {
    if (_closed || next == query) return;
    query = next;
    load();
  }

  /// A new post shows on top of the default list, so the list goes back to
  /// it from any sort, filter or search.
  void _onCreated(FeedbackItem _) {
    if (_closed || query.isDefault) return;
    _searchTimer?.cancel();
    searchController.clear();
    searchOpen = false;
    query = const FeedbackQuery();
    load();
  }

  void _onList(FeedbackList list) {
    if (_closed || list.query != query) return;
    items = list.page.items;
    _shownQuery = list.query;
    hasMore = list.page.nextCursor != null;
    error = null;
    if (state != LoadingState.loadingMore) {
      state = items.isEmpty ? LoadingState.empty : LoadingState.success;
    }
    update();
  }

  static Set<T> _toggled<T>(Set<T> values, T value) =>
      values.contains(value) ? ({...values}..remove(value)) : {...values, value};
}
