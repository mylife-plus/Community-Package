import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/cache/prefs_cache.dart';
import '../../core/errors/app_error.dart';
import '../../core/identity/device_details.dart';
import '../models/feedback_item.dart';
import '../models/feedback_query.dart';

/// Feedback of the host app. Owns the list stream.
///
/// Each query (sort, filters, search) has its own list. The first page goes
/// through the 3-tier cache: memory for every recent query, disk only for
/// the default one, then the network. Every value it resolves, cached or
/// fresh, is pushed to [feedbackListStream] with its query.
class FeedbackRepository {
  FeedbackRepository(this._api, this._cache);

  /// Not tuned yet. Every cache hit revalidates in the background anyway;
  /// this only limits how old the list may be when it is shown at startup.
  static const listCacheTtl = Duration(hours: 24);

  /// Not tuned yet: how many lists with a sort, filter or search stay in
  /// memory besides the default one, so switching back to them is instant.
  static const maxCachedQueries = 8;

  static const _defaultQuery = FeedbackQuery();

  final ApiClient _api;
  final PrefsCache _cache;
  final _listController = StreamController<FeedbackList>.broadcast();
  final _createdController = StreamController<FeedbackItem>.broadcast();

  /// Memory tier: the lists of [_memoryKey]'s app and language, least
  /// recently used first.
  final _lists = <FeedbackQuery, _QueryLists>{};
  String? _memoryKey;

  /// Hearts being sent: feedback number to the state the user asked for.
  final _pendingReactions = <int, bool>{};

  /// Every page of a list loaded so far, with the query it belongs to.
  Stream<FeedbackList> get feedbackListStream => _listController.stream;

  /// Feedback the user just posted.
  Stream<FeedbackItem> get createdStream => _createdController.stream;

  String get _languageKey => '${_api.appId}_${_api.languageCode}';

  // v2: the list cursor changed format, so lists saved by older versions
  // are not read back.
  String get _diskKey => 'feedback_list_v2_$_languageKey';

  /// The first page of [query]'s list.
  ///
  /// [forceRefresh] is pull-to-refresh: it skips both caches and, on
  /// failure, throws without touching the cache or the stream.
  Future<FeedbackPage> getFeedbackList({
    FeedbackQuery query = _defaultQuery,
    bool forceRefresh = false,
  }) async {
    final lists = _listsFor(query);

    final inMemory = lists.firstPage;
    if (!forceRefresh && inMemory != null) {
      _publish(query, lists, inMemory);
      unawaited(_revalidate(query, lists));
      return inMemory;
    }

    if (!forceRefresh && query.isDefault) {
      final onDisk = await _readDisk(ignoreTtl: false);
      if (onDisk != null && _isCurrent(query, lists)) {
        lists.firstPage = onDisk;
        _publish(query, lists, onDisk);
        unawaited(_revalidate(query, lists));
        return onDisk;
      }
    }

    try {
      return await _fetchFirstPage(query, lists);
    } on AppError {
      if (forceRefresh) rethrow;
      final fallback = await _lastGood(query, lists);
      if (fallback == null) rethrow;
      _publish(query, lists, fallback);
      return fallback;
    }
  }

  /// Loads the page after the last one loaded for [query] and publishes the
  /// longer list. Does nothing when everything is loaded or a load is
  /// already running.
  Future<void> loadMore({FeedbackQuery query = _defaultQuery}) {
    final lists = _memoryKey == _languageKey ? _lists[query] : null;
    if (lists == null) return Future.value();
    final running = lists.nextPageRequest;
    if (running != null) return running;
    final cursor = lists.all?.nextCursor;
    if (cursor == null) return Future.value();

    late final Future<void> request;
    request = _fetchNextPage(query, lists, cursor).whenComplete(() {
      if (identical(lists.nextPageRequest, request)) lists.nextPageRequest = null;
    });
    lists.nextPageRequest = request;
    return request;
  }

  /// Hearts the feedback ([on]) or takes the heart back.
  ///
  /// Every list shows the change at once, then the server's count. On
  /// failure every list goes back and the [AppError] is thrown. While a
  /// heart for the same feedback is on its way, further calls for it do
  /// nothing.
  Future<void> setReaction(FeedbackItem item, {required bool on}) async {
    final number = item.number;
    if (_pendingReactions.containsKey(number)) return;
    _pendingReactions[number] = on;
    unawaited(_replaceItem(number, (current) => _withReaction(current, on)));
    try {
      final path = '/feedback/$number/reaction';
      final fresh = FeedbackItem.fromJson(
        on ? await _api.putJson(path) : await _api.deleteJson(path),
      );
      await _replaceItem(number, (_) => fresh, persist: true);
    } on AppError {
      await _replaceItem(number, (current) => _withReaction(current, !on), persist: true);
      rethrow;
    } finally {
      _pendingReactions.remove(number);
    }
  }

  /// Posts new feedback and puts it at the top of the default list: in
  /// memory, on disk and on [feedbackListStream]. Then announces it on
  /// [createdStream].
  Future<FeedbackItem> createFeedback({required FeedbackType type, required String text}) =>
      _create({'type': type.name, 'text': text});

  /// Posts a Problem, like [createFeedback]. The backend builds its text
  /// from [description] and [steps].
  Future<FeedbackItem> createProblem({
    required List<String> steps,
    String? screenPath,
    String? description,
    DeviceDetails device = DeviceDetails.unknown,
  }) => _create({
    'type': FeedbackType.problem.name,
    'steps': steps,
    'screenPath': screenPath,
    'description': description,
    'osVersion': device.osVersion,
    'appVersion': device.appVersion,
    'deviceModel': device.deviceModel,
  });

  Future<FeedbackItem> _create(Map<String, Object?> body) async {
    final item = FeedbackItem.fromJson(await _api.postJson('/feedback', body));
    await _addToTop(item);
    if (!_createdController.isClosed) _createdController.add(item);
    return item;
  }

  /// Drops every cached list, for example when the app ID changes.
  Future<void> clearCache() async {
    final diskKey = _diskKey;
    _lists.clear();
    _memoryKey = null;
    await _cache.remove(diskKey);
  }

  void dispose() {
    _listController.close();
    _createdController.close();
  }

  /// [query]'s lists, now the most recently used. Lists of another app or
  /// language are dropped first.
  _QueryLists _listsFor(FeedbackQuery query) {
    final key = _languageKey;
    if (_memoryKey != key) {
      _lists.clear();
      _memoryKey = key;
    }
    final lists = _lists.remove(query) ?? _QueryLists();
    _lists[query] = lists;

    final others = _lists.keys.where((q) => !q.isDefault).toList();
    for (var i = 0; i < others.length - maxCachedQueries; i++) {
      _lists.remove(others[i]);
    }
    return lists;
  }

  /// Whether [lists] are still the memory tier's lists for [query]: not
  /// dropped by a post, an eviction or a change of language.
  bool _isCurrent(FeedbackQuery query, _QueryLists lists) =>
      _memoryKey == _languageKey && identical(_lists[query], lists);

  Future<FeedbackPage> _fetchFirstPage(FeedbackQuery query, _QueryLists lists) {
    final running = lists.firstPageRequest;
    if (running != null) return running;

    final diskKey = _diskKey;
    late final Future<FeedbackPage> request;
    request = () async {
      final page = _withPendingReactions(
        FeedbackPage.fromJson(await _api.getJson('/feedback', query: query.toQueryParameters())),
      );
      // A post, a logout or a newer request may have replaced this one meanwhile.
      if (!_isCurrent(query, lists) || !identical(lists.firstPageRequest, request)) return page;
      if (query.isDefault) await _cache.write(diskKey, page.toJson());
      lists.firstPage = page;
      _publish(query, lists, page);
      return page;
    }().whenComplete(() {
      if (identical(lists.firstPageRequest, request)) lists.firstPageRequest = null;
    });
    lists.firstPageRequest = request;
    return request;
  }

  Future<void> _fetchNextPage(FeedbackQuery query, _QueryLists lists, String cursor) async {
    final next = _withPendingReactions(
      FeedbackPage.fromJson(
        await _api.getJson('/feedback', query: {...query.toQueryParameters(), 'cursor': cursor}),
      ),
    );
    // A refresh moved the list on while this page loaded. A heart changes
    // items but not the cursor, so the page still fits after it.
    final list = lists.all;
    if (!_isCurrent(query, lists) || list == null || list.nextCursor != cursor) return;
    final known = {for (final item in list.items) item.number};
    _publish(
      query,
      lists,
      FeedbackPage(
        items: [...list.items, ...next.items.where((i) => !known.contains(i.number))],
        nextCursor: next.nextCursor,
      ),
    );
  }

  /// Background refresh after a cache hit. Never throws: the user already
  /// has data on screen.
  Future<void> _revalidate(FeedbackQuery query, _QueryLists lists) async {
    try {
      await _fetchFirstPage(query, lists);
    } catch (e) {
      debugPrint('community: list revalidation failed: $e');
    }
  }

  Future<FeedbackPage?> _lastGood(FeedbackQuery query, _QueryLists lists) async {
    final inMemory = lists.firstPage;
    if (inMemory != null) return inMemory;
    if (!query.isDefault) return null;
    final onDisk = await _readDisk(ignoreTtl: true);
    if (onDisk != null && _isCurrent(query, lists)) lists.firstPage = onDisk;
    return onDisk;
  }

  Future<FeedbackPage?> _readDisk({required bool ignoreTtl}) async {
    final key = _diskKey;
    final json = await _cache.read(key, ttl: listCacheTtl, ignoreTtl: ignoreTtl);
    if (json is! Map<String, dynamic>) return null;
    try {
      return FeedbackPage.fromJson(json);
    } catch (e) {
      debugPrint('community: unreadable cached list: $e');
      await _cache.remove(key);
      return null;
    }
  }

  /// The post is saved on the server by now, so nothing here may throw.
  Future<void> _addToTop(FeedbackItem item) async {
    // Lists with a sort, filter or search may not show the post, or not on
    // top. They are dropped and load again when shown.
    _lists.removeWhere((query, _) => !query.isDefault);
    final lists = _listsFor(_defaultQuery);
    // A list request still running was sent before this post existed. Its
    // answer must not replace the list that has the post.
    lists.firstPageRequest = null;

    final diskKey = _diskKey;
    final inMemory = lists.firstPage;
    final firstPage = inMemory ?? await _readDisk(ignoreTtl: true);
    if (firstPage == null) {
      // Nothing cached: load the list, which has the post.
      unawaited(_revalidate(_defaultQuery, lists));
      return;
    }

    final updated = _prepend(firstPage, item);
    try {
      await _cache.write(diskKey, updated.toJson());
    } catch (e) {
      debugPrint('community: could not cache the new post: $e');
    }
    final shown = inMemory != null ? (lists.all ?? firstPage) : firstPage;
    lists.firstPage = updated;
    _publish(_defaultQuery, lists, _prepend(shown, item));
  }

  /// Applies [update] to feedback [number] in every list in memory and
  /// publishes the lists that have it. [persist] also saves the default
  /// list to disk.
  Future<void> _replaceItem(
    int number,
    FeedbackItem Function(FeedbackItem) update, {
    bool persist = false,
  }) async {
    FeedbackPage? replaced(FeedbackPage? page) {
      if (page == null || !page.items.any((i) => i.number == number)) return null;
      return page.copyWith(
        items: [for (final i in page.items) i.number == number ? update(i) : i],
      );
    }

    for (final MapEntry(key: query, value: lists) in _lists.entries.toList()) {
      final first = replaced(lists.firstPage);
      if (first != null) lists.firstPage = first;
      final all = replaced(lists.all);
      if (all != null) _publish(query, lists, all);
    }

    if (!persist || _memoryKey != _languageKey) return;
    final defaultPage = _lists[_defaultQuery]?.firstPage;
    if (defaultPage == null || !defaultPage.items.any((i) => i.number == number)) return;
    try {
      await _cache.write(_diskKey, defaultPage.toJson());
    } catch (e) {
      debugPrint('community: could not cache the heart: $e');
    }
  }

  /// A page fetched while hearts are on their way shows them as asked.
  FeedbackPage _withPendingReactions(FeedbackPage page) {
    if (_pendingReactions.isEmpty) return page;
    return page.copyWith(
      items: [
        for (final item in page.items)
          switch (_pendingReactions[item.number]) {
            final on? => _withReaction(item, on),
            null => item,
          },
      ],
    );
  }

  static FeedbackItem _withReaction(FeedbackItem item, bool on) {
    if (item.reacted == on) return item;
    return item.copyWith(
      reacted: on,
      reactionCount: math.max(0, item.reactionCount + (on ? 1 : -1)),
    );
  }

  static FeedbackPage _prepend(FeedbackPage page, FeedbackItem item) => page.copyWith(
    items: [item, ...page.items.where((i) => i.number != item.number)],
  );

  void _publish(FeedbackQuery query, _QueryLists lists, FeedbackPage page) {
    lists.all = page;
    if (!_listController.isClosed) _listController.add(FeedbackList(query, page));
  }
}

/// One query's lists in the memory tier, and its requests.
class _QueryLists {
  /// The first page, as served from memory.
  FeedbackPage? firstPage;

  /// Every page loaded so far.
  FeedbackPage? all;

  Future<FeedbackPage>? firstPageRequest;
  Future<void>? nextPageRequest;
}
