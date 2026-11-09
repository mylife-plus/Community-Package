import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

void main() {
  late FakeBackend backend;
  late FeedbackRepository repo;
  late List<FeedbackItem> items;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    repo = backend.repository();
    items = [];
    repo.itemStream.listen(items.add);
  });

  test('loads feedback nobody has in memory from the server', () async {
    backend.answerAt('GET', '/v1/feedback/3', feedbackJson(3, commentCount: 2));

    final item = await repo.getFeedback(3);
    await pumpEventQueue();

    expect(item.commentCount, 2);
    expect(items.map((i) => i.commentCount), [2]);
    expect(backend.requests.single.url.path, '/v1/feedback/3');
  });

  test('shows the copy from a list at once, then the server copy', () async {
    backend.answer(pageJson([3, 2, 1]));
    await repo.getFeedbackList();
    backend.answerAt('GET', '/v1/feedback/3', feedbackJson(3, commentCount: 5));

    final item = await repo.getFeedback(3);
    await pumpEventQueue();

    expect(item.commentCount, 0);
    expect(items.map((i) => i.commentCount), [0, 5]);
  });

  test('a network failure keeps the copy in memory', () async {
    backend.answer(pageJson([3]));
    await repo.getFeedbackList();
    backend.failAt('GET', '/v1/feedback/3');

    final item = await repo.getFeedback(3);
    await pumpEventQueue();

    expect(item.number, 3);
  });

  test('feedback deleted on the server is not served from memory', () async {
    backend.answerAt('GET', '/v1/feedback/3', feedbackJson(3));
    await repo.getFeedback(3);
    backend.failAt('GET', '/v1/feedback/3', status: 404, code: 'not_found');

    await expectLater(
      repo.getFeedback(3, forceRefresh: true),
      throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.notFound)),
    );
  });

  test('pull-to-refresh throws on failure', () async {
    backend.answerAt('GET', '/v1/feedback/3', feedbackJson(3));
    await repo.getFeedback(3);
    backend.failAt('GET', '/v1/feedback/3');

    await expectLater(repo.getFeedback(3, forceRefresh: true), throwsA(isA<AppError>()));
  });

  test('updateItem changes the lists, the detail copy and the disk list', () async {
    final lists = <List<int>>[];
    repo.feedbackListStream.listen((l) => lists.add([for (final i in l.page.items) i.commentCount]));
    backend.answer(pageJson([3, 2]));
    await repo.getFeedbackList();

    await repo.updateItem(FeedbackItem.fromJson(feedbackJson(3, commentCount: 4)));
    await pumpEventQueue();

    expect(lists.last, [4, 0]);
    expect(items.last.commentCount, 4);
    final restarted = backend.repository();
    backend.answer(pageJson([3, 2]));
    final fromDisk = await restarted.getFeedbackList();
    expect(fromDisk.items.first.commentCount, 4);
  });

  test('a heart on feedback only open in its detail shows on the item stream', () async {
    backend.answerAt('GET', '/v1/feedback/7', feedbackJson(7));
    await repo.getFeedback(7);
    items.clear();
    backend.answerAt('PUT', '/v1/feedback/7/reaction', feedbackJson(7, reactionCount: 1, reacted: true));

    await repo.setReaction(FeedbackItem.fromJson(feedbackJson(7)), on: true);
    await pumpEventQueue();

    expect(items.map((i) => (i.reacted, i.reactionCount)), [(true, 1), (true, 1)]);
  });
}
