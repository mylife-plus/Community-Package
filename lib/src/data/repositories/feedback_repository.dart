import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/cache/prefs_cache.dart';
import '../../core/errors/app_error.dart';
import '../../core/identity/device_details.dart';
import '../models/feedback_item.dart';

/// Feedback of the host app. Owns the list stream.
///
/// The first page goes through the 3-tier cache (memory, disk, network).
/// Every value it resolves, cached or fresh, is pushed to [feedbackListStream].
class FeedbackRepository {
  FeedbackRepository(this._api, this._cache);

  /// Not tuned yet. Every cache hit revalidates in the background anyway;
  /// this only limits how old the list may be when it is shown at startup.
  static const listCacheTtl = Duration(hours: 24);

  final ApiClient _api;
  final PrefsCache _cache;
  final _listController = StreamController<FeedbackPage>.broadcast();

  /// Memory tier: the first page, and which app and language it belongs to.
  FeedbackPage? _firstPage;
  String? _firstPageKey;

  /// Everything loaded so far: the first page plus any further pages.
  FeedbackPage? _list;

  Future<FeedbackPage>? _firstPageRequest;
  Future<void>? _nextPageRequest;

  /// Every page of the list loaded so far.
  Stream<FeedbackPage> get feedbackListStream => _listController.stream;

  String get _listKey => 'feedback_list_${_api.appId}_${_api.languageCode}';

  /// The first page of the list, newest first.
  ///
  /// [forceRefresh] is pull-to-refresh: it skips both caches and, on
  /// failure, throws without touching the cache or the stream.
  Future<FeedbackPage> getFeedbackList({bool forceRefresh = false}) async {
    final key = _listKey;

    final inMemory = _firstPage;
    if (!forceRefresh && inMemory != null && _firstPageKey == key) {
      _publish(inMemory);
      unawaited(_revalidate(key));
      return inMemory;
    }

    if (!forceRefresh) {
      final onDisk = await _readDisk(key, ignoreTtl: false);
      if (onDisk != null) {
        _setFirstPage(key, onDisk);
        _publish(onDisk);
        unawaited(_revalidate(key));
        return onDisk;
      }
    }

    try {
      return await _fetchFirstPage(key);
    } on AppError {
      if (forceRefresh) rethrow;
      final fallback = await _lastGood(key);
      if (fallback == null) rethrow;
      _publish(fallback);
      return fallback;
    }
  }

  /// Loads the page after the last one loaded and publishes the longer list.
  /// Does nothing when everything is loaded or a load is already running.
  Future<void> loadMore() {
    final running = _nextPageRequest;
    if (running != null) return running;
    final list = _list;
    final cursor = list?.nextCursor;
    if (list == null || cursor == null) return Future.value();

    late final Future<void> request;
    request = _fetchNextPage(list, cursor).whenComplete(() {
      if (identical(_nextPageRequest, request)) _nextPageRequest = null;
    });
    _nextPageRequest = request;
    return request;
  }

  /// Posts new feedback and puts it at the top of the list: in memory, on
  /// disk and on [feedbackListStream].
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
    return item;
  }

  /// Drops every cached list, for example when the app ID changes.
  Future<void> clearCache() async {
    _firstPage = null;
    _firstPageKey = null;
    _list = null;
    _firstPageRequest = null;
    _nextPageRequest = null;
    await _cache.remove(_listKey);
  }

  void dispose() => _listController.close();

  Future<FeedbackPage> _fetchFirstPage(String key) {
    final running = _firstPageRequest;
    if (running != null) return running;

    late final Future<FeedbackPage> request;
    request = () async {
      final page = FeedbackPage.fromJson(await _api.getJson('/feedback'));
      // A logout or a newer request may have replaced this one meanwhile.
      if (!identical(_firstPageRequest, request)) return page;
      await _cache.write(key, page.toJson());
      _setFirstPage(key, page);
      _publish(page);
      return page;
    }().whenComplete(() {
      if (identical(_firstPageRequest, request)) _firstPageRequest = null;
    });
    _firstPageRequest = request;
    return request;
  }

  Future<void> _fetchNextPage(FeedbackPage list, String cursor) async {
    final next = FeedbackPage.fromJson(
      await _api.getJson('/feedback', query: {'cursor': cursor}),
    );
    // The list was replaced (refresh or revalidation) while this page loaded.
    if (!identical(_list, list)) return;
    final known = {for (final item in list.items) item.number};
    _publish(
      FeedbackPage(
        items: [...list.items, ...next.items.where((i) => !known.contains(i.number))],
        nextCursor: next.nextCursor,
      ),
    );
  }

  /// Background refresh after a cache hit. Never throws: the user already
  /// has data on screen.
  Future<void> _revalidate(String key) async {
    try {
      await _fetchFirstPage(key);
    } catch (e) {
      debugPrint('community: list revalidation failed: $e');
    }
  }

  Future<FeedbackPage?> _lastGood(String key) async {
    final inMemory = _firstPage;
    if (inMemory != null && _firstPageKey == key) return inMemory;
    final onDisk = await _readDisk(key, ignoreTtl: true);
    if (onDisk != null) _setFirstPage(key, onDisk);
    return onDisk;
  }

  Future<FeedbackPage?> _readDisk(String key, {required bool ignoreTtl}) async {
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
    final key = _listKey;
    // A list request still running was sent before this post existed. Its
    // answer must not replace the list that has the post.
    _firstPageRequest = null;

    final inMemory = _firstPageKey == key ? _firstPage : null;
    final firstPage = inMemory ?? await _readDisk(key, ignoreTtl: true);
    if (firstPage == null) {
      // Nothing cached: load the list, which has the post.
      unawaited(_revalidate(key));
      return;
    }

    final updated = _prepend(firstPage, item);
    try {
      await _cache.write(key, updated.toJson());
    } catch (e) {
      debugPrint('community: could not cache the new post: $e');
    }
    final shown = inMemory != null ? (_list ?? firstPage) : firstPage;
    _setFirstPage(key, updated);
    _publish(_prepend(shown, item));
  }

  static FeedbackPage _prepend(FeedbackPage page, FeedbackItem item) => page.copyWith(
    items: [item, ...page.items.where((i) => i.number != item.number)],
  );

  void _setFirstPage(String key, FeedbackPage page) {
    _firstPage = page;
    _firstPageKey = key;
  }

  void _publish(FeedbackPage list) {
    _list = list;
    if (!_listController.isClosed) _listController.add(list);
  }
}
