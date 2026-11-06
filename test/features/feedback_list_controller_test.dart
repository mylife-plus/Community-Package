import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/state/loading_state.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _tag = 'community_test_list';

void main() {
  late FakeBackend backend;

  FeedbackListController start() =>
      Get.put(FeedbackListController(backend.repository()), tag: _tag);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  tearDown(() => Get.delete<FeedbackListController>(tag: _tag, force: true));

  test('loads the list from the repository into success', () async {
    backend.answer(pageJson([3, 2, 1], nextCursor: 'c1'));

    final controller = start();
    expect(controller.state, LoadingState.loading);
    await pumpEventQueue();

    expect(controller.state, LoadingState.success);
    expect(controller.items.map((i) => i.number), [3, 2, 1]);
    expect(controller.hasMore, isTrue);
  });

  test('an empty list is the empty state', () async {
    backend.answer(pageJson([]));

    final controller = start();
    await pumpEventQueue();

    expect(controller.state, LoadingState.empty);
  });

  test('a failed first load is the error state, and retry recovers', () async {
    backend.fail();

    final controller = start();
    await pumpEventQueue();

    expect(controller.state, LoadingState.error);
    expect(controller.error?.type, AppErrorType.server);

    backend.answer(pageJson([1]));
    await controller.load();
    await pumpEventQueue();

    expect(controller.state, LoadingState.success);
    expect(controller.error, isNull);
  });

  test('loadMore appends, then stops at the last page', () async {
    backend.answer(pageJson([4, 3], nextCursor: 'c1'));
    final controller = start();
    await pumpEventQueue();

    backend.answer(pageJson([2, 1]));
    await controller.loadMore();
    await pumpEventQueue();

    expect(controller.items.map((i) => i.number), [4, 3, 2, 1]);
    expect(controller.hasMore, isFalse);
    expect(controller.state, LoadingState.success);

    await controller.loadMore();
    expect(backend.requests, hasLength(2));
  });

  test('a failed page keeps the list and records the error', () async {
    backend.answer(pageJson([2], nextCursor: 'c1'));
    final controller = start();
    await pumpEventQueue();

    backend.fail();
    await controller.loadMore();

    expect(controller.items.map((i) => i.number), [2]);
    expect(controller.loadMoreError, isNotNull);
    expect(controller.state, LoadingState.success);
  });

  test('a failed refresh returns the error and keeps the list', () async {
    backend.answer(pageJson([1]));
    final controller = start();
    await pumpEventQueue();

    backend.fail(status: 503);
    final error = await controller.refreshList();

    expect(error?.type, AppErrorType.server);
    expect(controller.items.map((i) => i.number), [1]);
  });
}
