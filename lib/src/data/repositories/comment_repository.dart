import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import '../models/comment_query.dart';
import '../models/feedback_comment.dart';
import '../models/feedback_item.dart';
import 'feedback_repository.dart';

/// Comments of the host app's feedback. Owns the comment stream.
///
/// Each feedback and query (sort, filters, search) has its own list, kept in
/// memory for the most recently opened feedback; there is no disk tier.
/// Every value it resolves, cached or fresh, is pushed to [commentsStream].
/// A post or delete hands the feedback's new comment count to
/// [FeedbackRepository], so its cards update everywhere.
class CommentRepository {
  CommentRepository(this._api, this._feedback);

  /// Not tuned yet: for how many feedback the comments stay in memory.
  static const maxCachedFeedback = 10;

  static const _defaultQuery = CommentQuery();

  final ApiClient _api;
  final FeedbackRepository _feedback;
  final _controller = StreamController<CommentList>.broadcast();

  /// Memory tier: feedback number to its lists by query, least recently
  /// opened first, for [_memoryKey]'s app and language.
  final _cache = <int, Map<CommentQuery, _CommentLists>>{};
  String? _memoryKey;

  /// Every page of a feedback's comments loaded so far, with its query.
  Stream<CommentList> get commentsStream => _controller.stream;

  String get _languageKey => '${_api.appId}_${_api.languageCode}';

  /// The first page of feedback [number]'s comments for [query].
  ///
  /// [forceRefresh] is pull-to-refresh: it skips memory and, on failure,
  /// throws without touching the cache or the stream.
  Future<CommentPage> getComments(
    int number, {
    CommentQuery query = _defaultQuery,
    bool forceRefresh = false,
  }) async {
    final lists = _listsFor(number, query);
    final inMemory = lists.firstPage;
    if (!forceRefresh && inMemory != null) {
      _publish(number, query, lists, lists.all ?? inMemory);
      unawaited(_revalidate(number, query, lists));
      return inMemory;
    }
    try {
      return await _fetchFirstPage(number, query, lists);
    } on AppError {
      if (forceRefresh || inMemory == null) rethrow;
      _publish(number, query, lists, lists.all ?? inMemory);
      return inMemory;
    }
  }

  /// Loads the page after the last one loaded and publishes the longer
  /// list. Does nothing when everything is loaded or a load is running.
  Future<void> loadMore(int number, {CommentQuery query = _defaultQuery}) {
    final byQuery = _memoryKey == _languageKey ? _cache[number] : null;
    final lists = byQuery == null ? null : byQuery[query];
    if (lists == null) return Future.value();
    final running = lists.nextPageRequest;
    if (running != null) return running;
    final cursor = lists.all?.nextCursor;
    if (cursor == null) return Future.value();

    late final Future<void> request;
    request = _fetchNextPage(number, query, lists, cursor).whenComplete(() {
      if (identical(lists.nextPageRequest, request)) lists.nextPageRequest = null;
    });
    lists.nextPageRequest = request;
    return request;
  }

  /// Posts a comment on feedback [number], or a reply to top-level comment
  /// [parentId]. A comment goes on top of the newest-first list (lists with
  /// another sort, filter or search load again when shown); a reply goes
  /// at the end of its thread in every list.
  Future<FeedbackComment> createComment(int number, String text, {int? parentId}) async {
    final json = await _api.postJson('/feedback/$number/comments', {
      'text': text,
      if (parentId != null) 'parentId': parentId,
    });
    final comment = _read(() => FeedbackComment.fromJson(json['comment'] as Map<String, dynamic>));
    await _updateFeedback(json);

    if (_memoryKey != _languageKey) return comment;
    final byQuery = _cache[number];
    if (byQuery == null) return comment;
    if (parentId == null) {
      byQuery.removeWhere((query, _) => !query.isDefault);
      final lists = byQuery[_defaultQuery];
      final all = lists?.all;
      if (lists != null && all != null) {
        // A request still running was sent before this comment existed.
        lists.firstPageRequest = null;
        lists.firstPage = _prepend(lists.firstPage ?? all, comment);
        _publish(number, _defaultQuery, lists, _prepend(all, comment));
      }
    } else {
      _updateEveryList(number, (thread) {
        if (thread.id != parentId) return thread;
        return thread.copyWith(
          replies: [...thread.replies, comment],
          replyCount: thread.replyCount + 1,
        );
      });
    }
    return comment;
  }

  /// Saves new [text] for the user's own [comment] on feedback [number].
  Future<FeedbackComment> editComment(int number, FeedbackComment comment, String text) async {
    final json = await _api.patchJson('/comments/${comment.id}', {'text': text});
    final fresh = _read(() => FeedbackComment.fromJson(json['comment'] as Map<String, dynamic>));
    _updateEveryList(number, (thread) {
      if (thread.id == fresh.id) return fresh;
      if (thread.id != fresh.parentId) return thread;
      return thread.copyWith(
        replies: [for (final reply in thread.replies) reply.id == fresh.id ? fresh : reply],
      );
    });
    return fresh;
  }

  /// Deletes the user's own [comment] on feedback [number], with the
  /// server's rules: a top-level comment with replies stays as a "Comment
  /// deleted" placeholder, anything else goes, and a placeholder goes with
  /// its last reply.
  Future<void> deleteComment(int number, FeedbackComment comment) async {
    final json = await _api.deleteJson('/comments/${comment.id}');
    await _updateFeedback(json);
    _updateEveryList(number, (thread) {
      if (thread.id == comment.id) {
        if (thread.replies.isEmpty) return null;
        return thread.copyWith(text: '', deleted: true, isMine: false, edited: false);
      }
      if (thread.id != comment.parentId) return thread;
      final replies = thread.replies.where((reply) => reply.id != comment.id).toList();
      if (replies.isEmpty && thread.deleted) return null;
      return thread.copyWith(replies: replies, replyCount: replies.length);
    });
  }

  /// Drops every cached list.
  void clearCache() {
    _cache.clear();
    _memoryKey = null;
  }

  void dispose() => _controller.close();

  /// The feedback with its new count, from a post or delete response. The
  /// comment is saved by now, so nothing here may throw.
  Future<void> _updateFeedback(Map<String, dynamic> json) async {
    try {
      await _feedback.updateItem(FeedbackItem.fromJson(json['feedback'] as Map<String, dynamic>));
    } catch (e) {
      debugPrint('community: could not update the comment count: $e');
    }
  }

  /// [number]'s lists for [query], now the most recently used. Lists of
  /// another app or language, and of feedback opened long ago, are dropped.
  _CommentLists _listsFor(int number, CommentQuery query) {
    final key = _languageKey;
    if (_memoryKey != key) {
      _cache.clear();
      _memoryKey = key;
    }
    final byQuery = _cache.remove(number) ?? <CommentQuery, _CommentLists>{};
    _cache[number] = byQuery;
    while (_cache.length > maxCachedFeedback) {
      _cache.remove(_cache.keys.first);
    }
    return byQuery.putIfAbsent(query, _CommentLists.new);
  }

  /// Whether [lists] are still the memory tier's lists for [number] and
  /// [query]: not dropped by a post, an eviction or a change of language.
  bool _isCurrent(int number, CommentQuery query, _CommentLists lists) =>
      _memoryKey == _languageKey && identical(_cache[number]?[query], lists);

  Future<CommentPage> _fetchFirstPage(int number, CommentQuery query, _CommentLists lists) {
    final running = lists.firstPageRequest;
    if (running != null) return running;

    late final Future<CommentPage> request;
    request = () async {
      final json = await _api.getJson('/feedback/$number/comments', query: query.toQueryParameters());
      final page = _read(() => CommentPage.fromJson(json));
      if (!_isCurrent(number, query, lists) || !identical(lists.firstPageRequest, request)) return page;
      lists.firstPage = page;
      _publish(number, query, lists, page);
      return page;
    }().whenComplete(() {
      if (identical(lists.firstPageRequest, request)) lists.firstPageRequest = null;
    });
    lists.firstPageRequest = request;
    return request;
  }

  Future<void> _fetchNextPage(int number, CommentQuery query, _CommentLists lists, String cursor) async {
    final json = await _api.getJson(
      '/feedback/$number/comments',
      query: {...query.toQueryParameters(), 'cursor': cursor},
    );
    final next = _read(() => CommentPage.fromJson(json));
    // A refresh or a post moved the list on while this page loaded.
    final list = lists.all;
    if (!_isCurrent(number, query, lists) || list == null || list.nextCursor != cursor) return;
    final known = {for (final comment in list.items) comment.id};
    _publish(
      number,
      query,
      lists,
      CommentPage(
        items: [...list.items, ...next.items.where((c) => !known.contains(c.id))],
        nextCursor: next.nextCursor,
      ),
    );
  }

  /// Background refresh after a cache hit. Never throws.
  Future<void> _revalidate(int number, CommentQuery query, _CommentLists lists) async {
    try {
      await _fetchFirstPage(number, query, lists);
    } catch (e) {
      debugPrint('community: comment revalidation failed: $e');
    }
  }

  /// Applies [update] to every top-level comment of [number] in every list
  /// and publishes the lists. [update] returns null to remove one.
  void _updateEveryList(int number, FeedbackComment? Function(FeedbackComment) update) {
    if (_memoryKey != _languageKey) return;
    final byQuery = _cache[number];
    if (byQuery == null) return;
    CommentPage? updated(CommentPage? page) =>
        page?.copyWith(items: page.items.map(update).whereType<FeedbackComment>().toList());
    for (final MapEntry(key: query, value: lists) in byQuery.entries.toList()) {
      lists.firstPage = updated(lists.firstPage);
      final all = updated(lists.all);
      if (all != null) _publish(number, query, lists, all);
    }
  }

  /// Reads a response with [parse]. A shape the app doesn't know becomes
  /// an [AppError], like any other failure.
  static T _read<T>(T Function() parse) {
    try {
      return parse();
    } on Object catch (e) {
      // TypeError from a cast, FormatException from a date: both are a
      // response this version can't read.
      debugPrint('community: unreadable comments response: $e');
      throw const AppError(AppErrorType.network, message: 'Unreadable response');
    }
  }

  static CommentPage _prepend(CommentPage page, FeedbackComment comment) => page.copyWith(
    items: [comment, ...page.items.where((c) => c.id != comment.id)],
  );

  void _publish(int number, CommentQuery query, _CommentLists lists, CommentPage page) {
    lists.all = page;
    if (!_controller.isClosed) _controller.add(CommentList(number, query, page));
  }
}

/// One feedback and query's comments in memory, and its requests.
class _CommentLists {
  /// The first page, as served from memory.
  CommentPage? firstPage;

  /// Every page loaded so far.
  CommentPage? all;

  Future<CommentPage>? firstPageRequest;
  Future<void>? nextPageRequest;
}
