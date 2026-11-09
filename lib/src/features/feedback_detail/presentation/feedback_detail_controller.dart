import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/state/loading_state.dart';
import '../../../data/models/comment_query.dart';
import '../../../data/models/feedback_comment.dart';
import '../../../data/models/feedback_item.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/feedback_repository.dart';

/// State of a feedback's detail screen: the feedback, its comments and
/// their toolbar, and the comment fields. Data arrives through the
/// repository streams.
class FeedbackDetailController extends GetxController {
  FeedbackDetailController({
    required this.number,
    required FeedbackRepository feedback,
    required CommentRepository comments,
  }) : _feedback = feedback,
       _comments = comments;

  /// Not tuned yet: the pause in typing before a search runs.
  static const searchDelay = Duration(milliseconds: 400);

  /// Longest search text; the backend allows the same.
  static const maxSearchLength = 100;

  /// Longest comment; the backend allows the same.
  static const maxCommentLength = 2000;

  /// The key of the new comment field in [isSending]. Comment IDs start at 1.
  static const newCommentKey = 0;

  /// The feedback's number.
  final int number;
  final FeedbackRepository _feedback;
  final CommentRepository _comments;
  StreamSubscription<FeedbackItem>? _itemSubscription;
  StreamSubscription<CommentList>? _commentSubscription;
  StreamSubscription<bool>? _reachableSubscription;
  Timer? _searchTimer;
  bool _closed = false;

  /// The feedback. Null until it has loaded.
  FeedbackItem? item;
  LoadingState itemState = LoadingState.idle;
  AppError? itemError;

  /// Top-level comments, each with its replies. While another query loads
  /// with the old list still on screen, [commentsState] is
  /// [LoadingState.loading] (see [isSwitching]).
  List<FeedbackComment> comments = const [];
  LoadingState commentsState = LoadingState.idle;
  bool hasMore = false;
  AppError? commentsError;
  AppError? loadMoreError;

  /// The sort, filters and search the comments show (or are loading).
  CommentQuery query = const CommentQuery();
  CommentQuery? _shownQuery;

  /// The toolbar shows the search field instead of its buttons.
  bool searchOpen = false;
  final searchController = TextEditingController();

  /// The + opened the new comment field.
  bool newCommentOpen = false;
  final newCommentController = TextEditingController();

  /// Reply fields, by top-level comment ID.
  final _replyControllers = <int, TextEditingController>{};

  /// Threads opened by the user. While a filter or search narrows the list,
  /// threads are open unless the user closed them ([_closedThreads]).
  final _openThreads = <int>{};
  final _closedThreads = <int>{};

  /// Comment fields whose text is on its way: [newCommentKey] or the
  /// top-level comment a reply goes to.
  final _sending = <int>{};

  bool get isSwitching => commentsState == LoadingState.loading && comments.isNotEmpty;

  /// The backend could not be reached.
  bool offline = false;

  /// The saved feedback is on screen while offline. Without it, the screen
  /// shows the full connection message instead.
  bool get showOfflineBar => offline && item != null;

  bool isSending(int key) => _sending.contains(key);

  bool isOpen(FeedbackComment thread) => query.narrows
      ? !_closedThreads.contains(thread.id)
      : _openThreads.contains(thread.id);

  /// The reply field of [thread], made when first asked for.
  TextEditingController replyController(FeedbackComment thread) =>
      _replyControllers.putIfAbsent(thread.id, TextEditingController.new);

  @override
  void onInit() {
    super.onInit();
    _itemSubscription = _feedback.itemStream.listen(_onItem);
    _commentSubscription = _comments.commentsStream.listen(_onComments);
    _reachableSubscription = _feedback.reachableStream.listen(_onReachable);
    offline = !_feedback.reachable;
    loadItem();
    loadComments();
  }

  @override
  void onClose() {
    _closed = true;
    _searchTimer?.cancel();
    _itemSubscription?.cancel();
    _commentSubscription?.cancel();
    _reachableSubscription?.cancel();
    searchController.dispose();
    newCommentController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  /// First load of the feedback, and its retry.
  Future<void> loadItem() async {
    if (item == null) {
      itemState = LoadingState.loading;
      itemError = null;
      update();
    }
    try {
      await _feedback.getFeedback(number);
    } on AppError catch (e) {
      if (_closed) return;
      // Deleted on the server: whatever is on screen is gone.
      if (item != null && e.type != AppErrorType.notFound) return;
      item = null;
      itemError = e;
      itemState = LoadingState.error;
      update();
    }
  }

  /// First load of the comments, a change of query, and the retry.
  Future<void> loadComments() async {
    final requested = query;
    if (_shownQuery != requested || comments.isEmpty) {
      commentsState = LoadingState.loading;
      commentsError = null;
      loadMoreError = null;
      update();
    }
    try {
      await _comments.getComments(number, query: requested);
    } on AppError catch (e) {
      if (_closed || query != requested) return;
      if (_shownQuery == requested && comments.isNotEmpty) return;
      comments = const [];
      _shownQuery = null;
      commentsError = e;
      commentsState = LoadingState.error;
      update();
    }
  }

  /// Pull-to-refresh of the feedback and its comments. Returns the error to
  /// tell the user about, if any; what is on screen stays as it was.
  Future<AppError?> refreshAll() async {
    try {
      await Future.wait([
        _feedback.getFeedback(number, forceRefresh: true),
        _comments.getComments(number, query: query, forceRefresh: true),
      ]);
      return null;
    } on AppError catch (e) {
      return e;
    }
  }

  /// Infinite scroll, and the retry after a failed page.
  Future<void> loadMore() async {
    if (!hasMore || commentsState != LoadingState.success) return;
    final requested = query;
    commentsState = LoadingState.loadingMore;
    loadMoreError = null;
    update();
    try {
      await _comments.loadMore(number, query: requested);
    } on AppError catch (e) {
      if (query == requested) loadMoreError = e;
    }
    if (_closed) return;
    if (commentsState == LoadingState.loadingMore) commentsState = LoadingState.success;
    update();
  }

  void setSort(CommentSort sort) => _show(query.copyWith(sort: sort));

  void toggleFilter(CommentFilter filter) {
    final filters = query.filters.contains(filter)
        ? ({...query.filters}..remove(filter))
        : {...query.filters, filter};
    _show(query.copyWith(filters: filters));
  }

  void resetFilter() => _show(query.copyWith(filters: const {}));

  void openSearch() {
    if (searchOpen) return;
    searchOpen = true;
    update();
  }

  /// The ✗ of the search field: closes it and shows the comments without
  /// a search.
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
    _show(query.copyWith(search: '', filters: const {}));
    update();
  }

  /// The + : opens or closes the new comment field.
  void toggleNewComment() {
    newCommentOpen = !newCommentOpen;
    update();
  }

  /// The replies chip: opens or closes [thread].
  void toggleThread(FeedbackComment thread) {
    final id = thread.id;
    final open = isOpen(thread);
    if (query.narrows) {
      open ? _closedThreads.add(id) : _closedThreads.remove(id);
    } else {
      open ? _openThreads.remove(id) : _openThreads.add(id);
    }
    update();
  }

  /// Hearts the feedback or takes the heart back. Returns the error to tell
  /// the user about, if any; the heart is back as it was by then.
  Future<AppError?> toggleReaction() async {
    final current = item;
    if (current == null) return null;
    try {
      await _feedback.setReaction(current, on: !current.reacted);
      return null;
    } on AppError catch (e) {
      return e;
    }
  }

  /// Sends the new comment field's text. Shows the newest comments first,
  /// so the comment is on top, and closes the field. Returns the error to
  /// tell the user about; the text stays in the field then.
  Future<AppError?> sendComment() =>
      _send(newCommentKey, newCommentController, () async {
        await _comments.createComment(number, newCommentController.text.trim());
        newCommentController.clear();
        newCommentOpen = false;
        _searchTimer?.cancel();
        searchController.clear();
        searchOpen = false;
        _openThreads.clear();
        _closedThreads.clear();
        _show(const CommentQuery());
      });

  /// Sends [thread]'s reply field. The thread stays open.
  Future<AppError?> sendReply(FeedbackComment thread) {
    final field = replyController(thread);
    return _send(thread.id, field, () async {
      await _comments.createComment(number, field.text.trim(), parentId: thread.id);
      field.clear();
      if (query.narrows) {
        _closedThreads.remove(thread.id);
      } else {
        _openThreads.add(thread.id);
      }
    });
  }

  /// Saves [text] for the user's own [comment]. Throws [AppError].
  Future<void> editComment(FeedbackComment comment, String text) =>
      _comments.editComment(number, comment, text.trim());

  /// Deletes the user's own [comment]. Throws [AppError].
  Future<void> deleteComment(FeedbackComment comment) => _comments.deleteComment(number, comment);

  Future<AppError?> _send(int key, TextEditingController field, Future<void> Function() send) async {
    if (_sending.contains(key) || field.text.trim().isEmpty) return null;
    _sending.add(key);
    update();
    try {
      await send();
      return null;
    } on AppError catch (e) {
      return e;
    } finally {
      _sending.remove(key);
      if (!_closed) update();
    }
  }

  void _show(CommentQuery next) {
    if (_closed || next == query) return;
    query = next;
    _closedThreads.clear();
    loadComments();
  }

  void _onReachable(bool reachable) {
    if (_closed) return;
    offline = !reachable;
    update();
  }

  void _onItem(FeedbackItem fresh) {
    if (_closed || fresh.number != number) return;
    item = fresh;
    itemError = null;
    itemState = LoadingState.success;
    update();
  }

  void _onComments(CommentList list) {
    if (_closed || list.number != number || list.query != query) return;
    comments = list.page.items;
    _shownQuery = list.query;
    hasMore = list.page.nextCursor != null;
    commentsError = null;
    if (commentsState != LoadingState.loadingMore) {
      commentsState = comments.isEmpty ? LoadingState.empty : LoadingState.success;
    }
    update();
  }
}
