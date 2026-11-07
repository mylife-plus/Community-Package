import 'dart:async';

import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/state/loading_state.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/models/feedback_query.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _tag = 'community_test_list_query';

void main() {
  late FakeBackend backend;
  late FeedbackRepository repository;

  Future<FeedbackListController> start(List<int> numbers) async {
    backend.answer(pageJson(numbers));
    final controller = Get.put(FeedbackListController(repository), tag: _tag);
    await pumpEventQueue();
    return controller;
  }

  List<int> numbers(FeedbackListController c) => [for (final i in c.items) i.number];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    repository = backend.repository();
  });

  tearDown(() => Get.delete<FeedbackListController>(tag: _tag, force: true));

  test('a new sort dims the old list until the new one arrives', () async {
    final controller = await start([3, 2, 1]);
    final gate = Completer<void>();
    backend.answerLater(gate.future, pageJson([1, 3, 2]));

    controller.setSort(FeedbackSort.reactions);
    await pumpEventQueue();

    expect(controller.isSwitching, isTrue);
    expect(numbers(controller), [3, 2, 1]);
    expect(backend.requests.last.url.queryParameters['sort'], 'reactions');

    gate.complete();
    await pumpEventQueue();
    expect(controller.state, LoadingState.success);
    expect(controller.isSwitching, isFalse);
    expect(numbers(controller), [1, 3, 2]);
  });

  test('switching back to a list already loaded is instant', () async {
    final controller = await start([3, 2, 1]);
    backend.answer(pageJson([1, 3, 2]));
    controller.setSort(FeedbackSort.reactions);
    await pumpEventQueue();

    // The revalidation behind the memory hit never answers here.
    backend.answerLater(Completer<void>().future, pageJson([3, 2, 1]));
    controller.setSort(FeedbackSort.newest);
    await pumpEventQueue();

    expect(controller.state, LoadingState.success);
    expect(numbers(controller), [3, 2, 1]);
  });

  test('filters add up, and reset clears them', () async {
    final controller = await start([3, 2, 1]);
    backend.answer(pageJson([3]));
    controller.toggleType(FeedbackType.idea);
    await pumpEventQueue();
    backend.answer(pageJson([3]));
    controller.toggleStatus(FeedbackStatus.inProgress);
    await pumpEventQueue();

    expect(backend.requests.last.url.queryParameters, {'type': 'idea', 'status': 'in_progress', 'lang': 'en'});
    expect(controller.query.hasFilter, isTrue);

    backend.answer(pageJson([3, 2, 1]));
    controller.resetFilter();
    await pumpEventQueue();
    expect(controller.query, const FeedbackQuery());
    expect(numbers(controller), [3, 2, 1]);
  });

  test('a query that finds nothing is empty, with the query kept', () async {
    final controller = await start([3, 2, 1]);
    backend.answer(pageJson([]));

    controller.toggleType(FeedbackType.problem);
    await pumpEventQueue();

    expect(controller.state, LoadingState.empty);
    expect(controller.query.types, {FeedbackType.problem});
  });

  test('a query that fails with nothing cached shows the error, not the old list', () async {
    final controller = await start([3, 2, 1]);
    backend.fail();

    controller.setSort(FeedbackSort.oldest);
    await pumpEventQueue();

    expect(controller.state, LoadingState.error);
    expect(controller.items, isEmpty);

    // Back to the default list, which is in memory.
    backend.answerLater(Completer<void>().future, pageJson([3, 2, 1]));
    controller.setSort(FeedbackSort.newest);
    await pumpEventQueue();
    expect(controller.state, LoadingState.success);
    expect(numbers(controller), [3, 2, 1]);
  });

  test('search runs on the trimmed text, and closing it shows every post again', () async {
    final controller = await start([3, 2, 1]);
    controller.openSearch();
    controller.searchController.text = '  barc ';
    backend.answer(pageJson([2]));

    controller.searchNow();
    await pumpEventQueue();

    expect(backend.requests.last.url.queryParameters['q'], 'barc');
    expect(numbers(controller), [2]);

    backend.answerLater(Completer<void>().future, pageJson([3, 2, 1]));
    controller.closeSearch();
    await pumpEventQueue();
    expect(controller.searchOpen, isFalse);
    expect(controller.searchController.text, isEmpty);
    expect(numbers(controller), [3, 2, 1]);
  });

  test('clear removes the search and the filters but keeps the sort', () async {
    final controller = await start([3, 2, 1]);
    backend.answer(pageJson([1, 2, 3]));
    controller.setSort(FeedbackSort.oldest);
    await pumpEventQueue();
    backend.answer(pageJson([]));
    controller.toggleType(FeedbackType.problem);
    await pumpEventQueue();

    backend.answer(pageJson([1, 2, 3]));
    controller.clearSearchAndFilter();
    await pumpEventQueue();

    expect(controller.query, const FeedbackQuery(sort: FeedbackSort.oldest));
    expect(numbers(controller), [1, 2, 3]);
  });

  test('a new post brings the list back to the default view', () async {
    final controller = await start([2, 1]);
    controller.openSearch();
    controller.searchController.text = 'barc';
    backend.answer(pageJson([1]));
    controller.searchNow();
    await pumpEventQueue();

    backend.answer(feedbackJson(3), status: 201);
    backend.answer(pageJson([3, 2, 1]));
    await repository.createFeedback(type: FeedbackType.idea, text: 'New');
    await pumpEventQueue();

    expect(controller.query, const FeedbackQuery());
    expect(controller.searchOpen, isFalse);
    expect(controller.searchController.text, isEmpty);
    expect(numbers(controller), [3, 2, 1]);
  });

  test('a heart shows at once; a failed one comes back as an error', () async {
    final controller = await start([2, 1]);
    final gate = Completer<void>();
    backend.answerLater(gate.future, feedbackJson(2, reactionCount: 1, reacted: true));

    final done = controller.toggleReaction(controller.items.first);
    await pumpEventQueue();
    expect(controller.items.first.reacted, isTrue);
    gate.complete();
    expect(await done, isNull);

    backend.fail(status: 429, code: 'rate_limited');
    final error = await controller.toggleReaction(controller.items.first);
    await pumpEventQueue();

    expect(error?.type, AppErrorType.rateLimited);
    expect(controller.items.first.reacted, isTrue);
    expect(controller.items.first.reactionCount, 1);
  });
}
