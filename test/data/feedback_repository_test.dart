import 'package:community_package/src/core/cache/prefs_cache.dart';
import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

List<int> _numbers(FeedbackPage page) => [for (final i in page.items) i.number];

void main() {
  late FakeBackend backend;
  late DateTime now;
  late FeedbackRepository repo;
  late List<List<int>> published;

  FeedbackRepository build() {
    final r = backend.repository(cache: PrefsCache(now: () => now));
    r.feedbackListStream.listen((page) => published.add(_numbers(page)));
    return r;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    now = DateTime(2026, 11, 6);
    published = [];
    repo = build();
  });

  test('first load comes from the network and is published', () async {
    backend.answer(pageJson([3, 2, 1]));

    final page = await repo.getFeedbackList();
    await pumpEventQueue();

    expect(_numbers(page), [3, 2, 1]);
    expect(published, [
      [3, 2, 1],
    ]);
  });

  test('a disk hit is published, then replaced by the fresh list', () async {
    backend.answer(pageJson([2, 1]));
    await repo.getFeedbackList();

    // A new repository, as after an app restart: memory is empty, disk is not.
    await pumpEventQueue();
    published.clear();
    backend.answer(pageJson([3, 2, 1]));
    final restarted = build();
    final page = await restarted.getFeedbackList();
    await pumpEventQueue();

    expect(_numbers(page), [2, 1]);
    expect(published, [
      [2, 1],
      [3, 2, 1],
    ]);
  });

  test('a memory hit is published and revalidated too', () async {
    backend.answer(pageJson([1]));
    await repo.getFeedbackList();
    await pumpEventQueue();
    published.clear();

    backend.answer(pageJson([2, 1]));
    final page = await repo.getFeedbackList();
    await pumpEventQueue();

    expect(_numbers(page), [1]);
    expect(published, [
      [1],
      [2, 1],
    ]);
    expect(backend.requests, hasLength(2));
  });

  test('a failed background refresh keeps the cached list quietly', () async {
    backend.answer(pageJson([1]));
    await repo.getFeedbackList();
    await pumpEventQueue();
    published.clear();

    backend.fail();
    final page = await repo.getFeedbackList();
    await pumpEventQueue();

    expect(_numbers(page), [1]);
    expect(published, [
      [1],
    ]);
  });

  test('when the network fails, a stale disk copy beats an error', () async {
    backend.answer(pageJson([2, 1]));
    await repo.getFeedbackList();

    now = now.add(FeedbackRepository.listCacheTtl + const Duration(hours: 1));
    await pumpEventQueue();
    published.clear();
    backend.fail();
    final restarted = build();
    final page = await restarted.getFeedbackList();
    await pumpEventQueue();

    expect(_numbers(page), [2, 1]);
    expect(published, [
      [2, 1],
    ]);
  });

  test('with nothing cached, a network failure throws an AppError', () async {
    backend.fail();

    await expectLater(repo.getFeedbackList(), throwsA(isA<AppError>()));
  });

  test('a failed pull-to-refresh throws and leaves the list alone', () async {
    backend.answer(pageJson([1]));
    await repo.getFeedbackList();
    await pumpEventQueue();
    published.clear();

    backend.fail();
    await expectLater(repo.getFeedbackList(forceRefresh: true), throwsA(isA<AppError>()));
    await pumpEventQueue();

    expect(published, isEmpty);
  });

  test('callers arriving during a load share one request', () async {
    backend.answer(pageJson([1]));

    await Future.wait([repo.getFeedbackList(), repo.getFeedbackList()]);

    expect(backend.requests, hasLength(1));
  });

  test('loadMore appends the next page using the cursor', () async {
    backend.answer(pageJson([4, 3], nextCursor: 'c1'));
    await repo.getFeedbackList();
    backend.answer(pageJson([2, 1]));

    await repo.loadMore();
    await repo.loadMore(); // last page reached: no request
    await pumpEventQueue();

    expect(backend.requests.last.url.queryParameters['cursor'], 'c1');
    expect(backend.requests, hasLength(2));
    expect(published.last, [4, 3, 2, 1]);
  });
}
