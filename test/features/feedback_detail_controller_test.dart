import 'dart:async';

import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/state/loading_state.dart';
import 'package:community_package/src/data/models/comment_query.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _item = '/v1/feedback/3';
const _comments = '/v1/feedback/3/comments';

void main() {
  late FakeBackend backend;
  late FeedbackDetailController controller;

  FeedbackDetailController build() {
    final feedback = backend.repository();
    return FeedbackDetailController(
      number: 3,
      feedback: feedback,
      comments: backend.commentRepository(feedback),
    )..onInit();
  }

  Map<String, String> lastCommentQuery() =>
      backend.requests.lastWhere((r) => r.method == 'GET' && r.url.path == _comments).url.queryParameters;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  tearDown(() => controller.onClose());

  Future<void> open({List<Map<String, dynamic>>? comments}) async {
    backend.answerAt('GET', _item, feedbackJson(3, status: 'in_progress', commentCount: 2));
    backend.answerAt(
      'GET',
      _comments,
      commentPageJson(comments ?? [commentJson(2, replies: [commentJson(5, parentId: 2)]), commentJson(1)]),
    );
    controller = build();
    await pumpEventQueue();
  }

  test('loads the feedback and its comments', () async {
    await open();

    expect(controller.itemState, LoadingState.success);
    expect(controller.item?.status?.name, 'inProgress');
    expect(controller.commentsState, LoadingState.success);
    expect(controller.comments.map((c) => c.id), [2, 1]);
  });

  test('feedback that no longer exists ends in a not-found error', () async {
    backend.failAt('GET', _item, status: 404, code: 'not_found');
    backend.failAt('GET', _comments, status: 404, code: 'not_found');
    controller = build();
    await pumpEventQueue();

    expect(controller.itemState, LoadingState.error);
    expect(controller.itemError?.type, AppErrorType.notFound);
  });

  test('no comments is the empty state', () async {
    await open(comments: []);

    expect(controller.commentsState, LoadingState.empty);
  });

  test('sort, filter and search reload the comments with their parameters', () async {
    await open();

    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    controller.setSort(CommentSort.replies);
    await pumpEventQueue();
    expect(lastCommentQuery()['sort'], 'replies');

    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    controller.toggleFilter(CommentFilter.mine);
    await pumpEventQueue();
    expect(lastCommentQuery()['filter'], 'mine');

    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    controller.openSearch();
    controller.searchController.text = ' scan ';
    controller.searchNow();
    await pumpEventQueue();
    expect(lastCommentQuery()['q'], 'scan');
    expect(controller.query, const CommentQuery(sort: CommentSort.replies, filters: {CommentFilter.mine}, search: 'scan'));
  });

  test('threads open on tap; a filter or search opens them by itself', () async {
    await open();
    final thread = controller.comments.first;
    expect(controller.isOpen(thread), isFalse);

    controller.toggleThread(thread);
    expect(controller.isOpen(thread), isTrue);
    controller.toggleThread(thread);
    expect(controller.isOpen(thread), isFalse);

    backend.answerAt('GET', _comments, commentPageJson([commentJson(2, replies: [commentJson(5, parentId: 2)])]));
    controller.toggleFilter(CommentFilter.admin);
    await pumpEventQueue();
    final filtered = controller.comments.single;
    expect(controller.isOpen(filtered), isTrue);
    controller.toggleThread(filtered);
    expect(controller.isOpen(filtered), isFalse);
  });

  test('a new comment goes back to the default view, on top, and closes the field', () async {
    await open();
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    controller.setSort(CommentSort.oldest);
    await pumpEventQueue();
    controller.toggleNewComment();
    controller.newCommentController.text = 'Nice';
    backend.answerAt('POST', _comments, {
      'comment': commentJson(9, text: 'Nice', isMine: true),
      'feedback': feedbackJson(3, commentCount: 3),
    }, status: 201);

    final error = await controller.sendComment();
    await pumpEventQueue();

    expect(error, isNull);
    expect(controller.query, const CommentQuery());
    expect(controller.comments.first.id, 9);
    expect(controller.newCommentOpen, isFalse);
    expect(controller.newCommentController.text, isEmpty);
    expect(controller.item?.commentCount, 3);
  });

  test('a reply keeps its thread open and clears its field', () async {
    await open();
    final thread = controller.comments.first;
    controller.replyController(thread).text = 'Agreed';
    backend.answerAt('POST', _comments, {
      'comment': commentJson(10, parentId: 2, text: 'Agreed', isMine: true),
      'feedback': feedbackJson(3, commentCount: 3),
    }, status: 201);

    await controller.sendReply(thread);
    await pumpEventQueue();

    expect(controller.comments.first.replies.map((r) => r.id), [5, 10]);
    expect(controller.isOpen(controller.comments.first), isTrue);
    expect(controller.replyController(thread).text, isEmpty);
  });

  test('a failed send keeps the text and returns the error; a second tap meanwhile is ignored', () async {
    await open();
    controller.newCommentController.text = 'Nice';
    final gate = Completer<void>();
    backend.answerAtLater(
      'POST',
      _comments,
      gate.future,
      {'error': {'code': 'rate_limited', 'message': 'x'}},
      status: 429,
    );

    final first = controller.sendComment();
    await pumpEventQueue();
    expect(controller.isSending(FeedbackDetailController.newCommentKey), isTrue);
    expect(await controller.sendComment(), isNull);
    gate.complete();
    final error = await first;

    expect(error?.type, AppErrorType.rateLimited);
    expect(controller.newCommentController.text, 'Nice');
    expect(controller.isSending(FeedbackDetailController.newCommentKey), isFalse);
    expect(backend.requests.where((r) => r.method == 'POST'), hasLength(1));
  });

  test('blank text is not sent', () async {
    await open();
    controller.newCommentController.text = '   ';

    expect(await controller.sendComment(), isNull);
    expect(backend.requests.where((r) => r.method == 'POST'), isEmpty);
  });
}
