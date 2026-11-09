import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/models/feedback_query.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

Matcher get _unreadable => throwsA(
  isA<AppError>()
      .having((e) => e.type, 'type', AppErrorType.network)
      .having((e) => e.message, 'message', 'Unreadable response'),
);

void main() {
  late FakeBackend backend;
  late FeedbackRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    repo = backend.repository();
  });

  test('a list the app cannot read is an AppError', () async {
    backend.answer({'items': 'not a list'});

    await expectLater(repo.getFeedbackList(), _unreadable);
  });

  test('a next page the app cannot read is an AppError', () async {
    backend.answer(pageJson([3, 2], nextCursor: 'c1'));
    await repo.getFeedbackList();
    backend.answer({'items': [{'number': 'one'}]});

    await expectLater(repo.loadMore(query: const FeedbackQuery()), _unreadable);
  });

  test('a detail the app cannot read is an AppError', () async {
    backend.answerAt('GET', '/v1/feedback/3', {'number': 'three'});

    await expectLater(repo.getFeedback(3), _unreadable);
  });

  test('a new post the app cannot read is an AppError', () async {
    backend.answer({'created': true});

    await expectLater(repo.createFeedback(type: FeedbackType.idea, text: 'Totals'), _unreadable);
  });

  test('a heart answer the app cannot read is an AppError and the heart goes back', () async {
    backend.answer(pageJson([3]));
    final page = await repo.getFeedbackList();
    final shown = <bool>[];
    repo.feedbackListStream.listen((list) => shown.add(list.page.items.single.reacted));
    backend.answerAt('PUT', '/v1/feedback/3/reaction', {'reacted': 'yes'});

    await expectLater(repo.setReaction(page.items.single, on: true), _unreadable);
    await pumpEventQueue();

    expect(shown.last, isFalse);
  });

}
