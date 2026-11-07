import 'dart:async';
import 'dart:convert';

import 'package:community_package/src/core/cache/prefs_cache.dart';
import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/identity/device_details.dart';
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
    r.feedbackListStream.listen((list) => published.add(_numbers(list.page)));
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

  group('createProblem', () {
    test('posts the steps, path, description and device details', () async {
      backend.answer({...feedbackJson(26, type: 'problem'), 'steps': ['Tap plus']}, status: 201);

      final item = await repo.createProblem(
        steps: ['Tap plus', 'Add an item'],
        screenPath: 'Inventory > Sell Items',
        description: 'Nothing happens',
        device: const DeviceDetails(osVersion: 'iOS 18.1', appVersion: '3.2.0', deviceModel: 'iPhone 15 Pro'),
      );

      expect(item.type, FeedbackType.problem);
      expect(jsonDecode(backend.requests.single.body), {
        'type': 'problem',
        'steps': ['Tap plus', 'Add an item'],
        'screenPath': 'Inventory > Sell Items',
        'description': 'Nothing happens',
        'osVersion': 'iOS 18.1',
        'appVersion': '3.2.0',
        'deviceModel': 'iPhone 15 Pro',
      });
    });

    test('sends null for what is not known', () async {
      backend.answer(feedbackJson(26, type: 'problem'), status: 201);

      await repo.createProblem(steps: ['Open the app']);

      expect(jsonDecode(backend.requests.single.body), {
        'type': 'problem',
        'steps': ['Open the app'],
        'screenPath': null,
        'description': null,
        'osVersion': null,
        'appVersion': null,
        'deviceModel': null,
      });
    });

    test('puts the new Problem on top of the list', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      await pumpEventQueue();
      published.clear();

      backend.answer(feedbackJson(3, type: 'problem'), status: 201);
      await repo.createProblem(steps: ['Open the app']);
      await pumpEventQueue();

      expect(published, [
        [3, 2, 1],
      ]);
    });
  });

  group('createFeedback', () {
    test('posts the type and text and returns the new item', () async {
      backend.answer(feedbackJson(26, type: 'improvement'), status: 201);

      final item = await repo.createFeedback(type: FeedbackType.improvement, text: 'Totals');

      expect(item.number, 26);
      expect(item.type, FeedbackType.improvement);
      final sent = backend.requests.single;
      expect(sent.method, 'POST');
      expect(sent.url.path, '/v1/feedback');
      expect(jsonDecode(sent.body), {'type': 'improvement', 'text': 'Totals'});
    });

    test('puts the new item on top of every loaded page', () async {
      backend.answer(pageJson([5, 4], nextCursor: 'c1'));
      await repo.getFeedbackList();
      backend.answer(pageJson([3, 2]));
      await repo.loadMore();
      await pumpEventQueue();
      published.clear();

      backend.answer(feedbackJson(6), status: 201);
      await repo.createFeedback(type: FeedbackType.idea, text: 'New');
      await pumpEventQueue();

      expect(published, [
        [6, 5, 4, 3, 2],
      ]);
    });

    test('the next memory and disk hits start with the new item', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      backend.answer(feedbackJson(3), status: 201);
      await repo.createFeedback(type: FeedbackType.idea, text: 'New');

      backend.answer(pageJson([3, 2, 1]));
      expect(_numbers(await repo.getFeedbackList()), [3, 2, 1]);

      // After a restart, from disk.
      await pumpEventQueue();
      backend.answer(pageJson([3, 2, 1]));
      expect(_numbers(await build().getFeedbackList()), [3, 2, 1]);
    });

    test('with nothing cached, the list is loaded from the network', () async {
      backend.answer(feedbackJson(3), status: 201);
      backend.answer(pageJson([3, 2, 1]));

      await repo.createFeedback(type: FeedbackType.idea, text: 'New');
      await pumpEventQueue();

      expect(backend.requests.map((r) => r.method), ['POST', 'GET']);
      expect(published, [
        [3, 2, 1],
      ]);
    });

    test('a list request sent before the post cannot replace the list', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      final gate = Completer<void>();
      backend.answerLater(gate.future, pageJson([2, 1]));
      await repo.getFeedbackList(); // memory hit; revalidation waits on gate
      await pumpEventQueue();

      backend.answer(feedbackJson(3), status: 201);
      await repo.createFeedback(type: FeedbackType.idea, text: 'New');
      gate.complete();
      await pumpEventQueue();

      expect(published.last, [3, 2, 1]);
      backend.answer(pageJson([3, 2, 1]));
      expect(_numbers(await repo.getFeedbackList()), [3, 2, 1]);
    });

    test('a failed post throws and leaves the list alone', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      await pumpEventQueue();
      published.clear();
      backend.fail(status: 429, code: 'rate_limited');

      await expectLater(
        repo.createFeedback(type: FeedbackType.idea, text: 'New'),
        throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.rateLimited)),
      );
      await pumpEventQueue();
      expect(published, isEmpty);
    });
  });
}
