import 'dart:async';

import 'package:community_package/src/core/cache/prefs_cache.dart';
import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/models/feedback_query.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _byHearts = FeedbackQuery(sort: FeedbackSort.reactions);
const _ideas = FeedbackQuery(types: {FeedbackType.idea});

List<int> _numbers(FeedbackPage page) => [for (final i in page.items) i.number];

FeedbackItem _item(int number, {int hearts = 0, bool reacted = false}) =>
    FeedbackItem.fromJson(feedbackJson(number, reactionCount: hearts, reacted: reacted));

void main() {
  late FakeBackend backend;
  late FeedbackRepository repo;
  late List<FeedbackList> published;

  FeedbackRepository build() {
    final r = backend.repository(cache: PrefsCache(now: () => DateTime(2026, 11, 7)));
    r.feedbackListStream.listen(published.add);
    return r;
  }

  /// What was published for [query], as numbers.
  List<List<int>> publishedFor(FeedbackQuery query) => [
    for (final list in published)
      if (list.query == query) _numbers(list.page),
  ];

  /// The hearts of feedback [number] in each list published for [query].
  List<(int, bool)> heartsOf(int number, {FeedbackQuery query = const FeedbackQuery()}) => [
    for (final list in published)
      if (list.query == query)
        for (final item in list.page.items)
          if (item.number == number) (item.reactionCount, item.reacted),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    published = [];
    repo = build();
  });

  group('FeedbackQuery', () {
    test('the default asks for nothing', () {
      expect(const FeedbackQuery().isDefault, isTrue);
      expect(const FeedbackQuery().toQueryParameters(), isEmpty);
    });

    test('sends sort, filters and search in a fixed order', () {
      const query = FeedbackQuery(
        sort: FeedbackSort.comments,
        types: {FeedbackType.idea, FeedbackType.improvement},
        statuses: {FeedbackStatus.done, FeedbackStatus.inProgress},
        search: '#21',
      );

      expect(query.toQueryParameters(), {
        'sort': 'comments',
        'type': 'improvement,idea',
        'status': 'in_progress,done',
        'q': '#21',
      });
      expect(query.isDefault, isFalse);
      expect(query.hasFilter, isTrue);
    });

    test('is equal whatever order the filters were ticked in', () {
      expect(
        const FeedbackQuery(types: {FeedbackType.idea, FeedbackType.problem}),
        const FeedbackQuery(types: {FeedbackType.problem, FeedbackType.idea}),
      );
    });
  });

  group('lists per query', () {
    test('asks the backend for the query and publishes it with the query', () async {
      backend.answer(pageJson([9, 4]));

      await repo.getFeedbackList(query: const FeedbackQuery(sort: FeedbackSort.reactions, search: 'barc'));
      await pumpEventQueue();

      final sent = backend.requests.single.url.queryParameters;
      expect(sent, {'sort': 'reactions', 'q': 'barc', 'lang': 'en'});
      expect(published.single.query, const FeedbackQuery(sort: FeedbackSort.reactions, search: 'barc'));
    });

    test('switching back to a query is a memory hit, revalidated behind it', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      backend.answer(pageJson([1, 2]));
      await repo.getFeedbackList(query: _byHearts);
      published.clear();

      final gate = Completer<void>();
      backend.answerLater(gate.future, pageJson([3, 2, 1]));
      final page = await repo.getFeedbackList();
      await pumpEventQueue();

      expect(_numbers(page), [2, 1]);
      expect(publishedFor(const FeedbackQuery()), [
        [2, 1],
      ]);
      gate.complete();
      await pumpEventQueue();
      expect(publishedFor(const FeedbackQuery()).last, [3, 2, 1]);
    });

    test('only the default list is saved on disk', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      backend.answer(pageJson([1]));
      await repo.getFeedbackList(query: _ideas);

      // After a restart, offline: the default list comes from disk, a
      // filtered one has nothing to show.
      final restarted = build();
      backend.fail();
      backend.fail();
      expect(_numbers(await restarted.getFeedbackList()), [2, 1]);
      await pumpEventQueue();
      await expectLater(restarted.getFeedbackList(query: _ideas), throwsA(isA<AppError>()));
    });

    test('loadMore sends the cursor with the query', () async {
      backend.answer(pageJson([5, 4], nextCursor: 'c1'));
      await repo.getFeedbackList(query: _ideas);
      backend.answer(pageJson([3]));

      await repo.loadMore(query: _ideas);
      await pumpEventQueue();

      expect(backend.requests.last.url.queryParameters, {'type': 'idea', 'cursor': 'c1', 'lang': 'en'});
      expect(publishedFor(_ideas).last, [5, 4, 3]);
    });

    test('keeps the default list and the 8 most recent others in memory', () async {
      backend.answer(pageJson([1]));
      await repo.getFeedbackList();
      for (var i = 0; i < FeedbackRepository.maxCachedQueries + 1; i++) {
        backend.answer(pageJson([i]));
        await repo.getFeedbackList(query: FeedbackQuery(search: 'word $i'));
      }
      await pumpEventQueue();
      final before = backend.requests.length;

      // The newest search and the default list are memory hits; the oldest
      // search was dropped and is fetched again.
      backend.answer(pageJson([8]));
      await repo.getFeedbackList(query: const FeedbackQuery(search: 'word 8'));
      backend.answer(pageJson([1]));
      await repo.getFeedbackList();
      final gate = Completer<void>();
      backend.answerLater(gate.future, pageJson([0]));
      final dropped = repo.getFeedbackList(query: const FeedbackQuery(search: 'word 0'));
      await pumpEventQueue();
      final lastPublished = published.last.query;
      gate.complete();
      await dropped;

      expect(backend.requests.length - before, 3);
      expect(lastPublished, isNot(const FeedbackQuery(search: 'word 0')));
    });

    test('a post drops the other lists and is announced', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList();
      backend.answer(pageJson([1]));
      await repo.getFeedbackList(query: _ideas);
      final created = <int>[];
      repo.createdStream.listen((item) => created.add(item.number));

      backend.answer(feedbackJson(3), status: 201);
      await repo.createFeedback(type: FeedbackType.idea, text: 'New');
      await pumpEventQueue();

      expect(created, [3]);
      expect(publishedFor(const FeedbackQuery()).last, [3, 2, 1]);
      // The idea list is not in memory any more: it loads again.
      backend.answer(pageJson([3, 1]));
      await repo.getFeedbackList(query: _ideas);
      expect(backend.requests.last.url.queryParameters['type'], 'idea');
    });
  });

  group('setReaction', () {
    Future<void> loadDefault(List<Map<String, dynamic>> items) async {
      backend.answer({'items': items, 'nextCursor': null});
      await repo.getFeedbackList();
      await pumpEventQueue();
      published.clear();
    }

    test('shows the heart at once, then the server count', () async {
      await loadDefault([feedbackJson(2, reactionCount: 4), feedbackJson(1)]);
      final gate = Completer<void>();
      backend.answerLater(gate.future, feedbackJson(2, reactionCount: 7, reacted: true));

      final done = repo.setReaction(_item(2, hearts: 4), on: true);
      await pumpEventQueue();
      expect(heartsOf(2), [(5, true)]);

      gate.complete();
      await done;
      await pumpEventQueue();
      expect(heartsOf(2).last, (7, true));
      final request = backend.requests.last;
      expect(request.method, 'PUT');
      expect(request.url.path, '/v1/feedback/2/reaction');
    });

    test('taking the heart back sends DELETE', () async {
      await loadDefault([feedbackJson(2, reactionCount: 4, reacted: true)]);
      backend.answer(feedbackJson(2, reactionCount: 3));

      await repo.setReaction(_item(2, hearts: 4, reacted: true), on: false);
      await pumpEventQueue();

      expect(backend.requests.last.method, 'DELETE');
      expect(heartsOf(2), [(3, false), (3, false)]);
    });

    test('changes the item in every list in memory', () async {
      backend.answer(pageJson([2, 1]));
      await repo.getFeedbackList(query: _byHearts);
      await loadDefault([feedbackJson(1), feedbackJson(2)]);
      backend.answer(feedbackJson(2, reactionCount: 1, reacted: true));

      await repo.setReaction(_item(2), on: true);
      await pumpEventQueue();

      expect(heartsOf(2).last, (1, true));
      expect(heartsOf(2, query: _byHearts).last, (1, true));
      // Hearts never move an item, also in the list sorted by hearts.
      expect(publishedFor(_byHearts).last, [2, 1]);
    });

    test('a failure puts the heart back and throws', () async {
      await loadDefault([feedbackJson(2, reactionCount: 4)]);
      backend.fail(status: 429, code: 'rate_limited');

      await expectLater(
        repo.setReaction(_item(2, hearts: 4), on: true),
        throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.rateLimited)),
      );
      await pumpEventQueue();

      expect(heartsOf(2), [(5, true), (4, false)]);
    });

    test('a second tap while one is on its way does nothing', () async {
      await loadDefault([feedbackJson(2)]);
      final gate = Completer<void>();
      backend.answerLater(gate.future, feedbackJson(2, reactionCount: 1, reacted: true));

      final first = repo.setReaction(_item(2), on: true);
      await pumpEventQueue();
      await repo.setReaction(_item(2, hearts: 1, reacted: true), on: false);
      gate.complete();
      await first;

      expect(backend.requests.where((r) => r.method != 'GET'), hasLength(1));
      // The next tap goes through again.
      backend.answer(feedbackJson(2));
      await repo.setReaction(_item(2, hearts: 1, reacted: true), on: false);
      expect(backend.requests.last.method, 'DELETE');
    });

    test('a list loaded while a heart is on its way shows the heart', () async {
      await loadDefault([feedbackJson(2)]);
      final gate = Completer<void>();
      backend.answerLater(gate.future, feedbackJson(2, reactionCount: 1, reacted: true));
      final heart = repo.setReaction(_item(2), on: true);
      await pumpEventQueue();

      // Pull-to-refresh answers with the count from before the heart.
      backend.answer(pageJson([2]));
      await repo.getFeedbackList(forceRefresh: true);
      await pumpEventQueue();
      expect(heartsOf(2).last, (1, true));

      gate.complete();
      await heart;
    });

    test('a page loaded during a heart is still added', () async {
      backend.answer({
        'items': [feedbackJson(3)],
        'nextCursor': 'c1',
      });
      await repo.getFeedbackList();
      final gate = Completer<void>();
      backend.answerLater(gate.future, pageJson([2, 1]));
      final more = repo.loadMore();
      await pumpEventQueue();

      backend.answer(feedbackJson(3, reactionCount: 1, reacted: true));
      await repo.setReaction(_item(3), on: true);
      gate.complete();
      await more;
      await pumpEventQueue();

      expect(publishedFor(const FeedbackQuery()).last, [3, 2, 1]);
      expect(heartsOf(3).last, (1, true));
    });

    test('the default list on disk keeps the heart', () async {
      await loadDefault([feedbackJson(2)]);
      backend.answer(feedbackJson(2, reactionCount: 1, reacted: true));
      await repo.setReaction(_item(2), on: true);

      final restarted = build();
      backend.fail();
      final page = await restarted.getFeedbackList();

      expect(page.items.single.reacted, isTrue);
      expect(page.items.single.reactionCount, 1);
    });
  });
}
