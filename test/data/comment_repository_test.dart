import 'dart:async';
import 'dart:convert';

import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/comment_query.dart';
import 'package:community_package/src/data/models/feedback_comment.dart';
import 'package:community_package/src/data/repositories/comment_repository.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _comments = '/v1/feedback/3/comments';

List<int> _ids(List<FeedbackComment> comments) => [for (final c in comments) c.id];

void main() {
  late FakeBackend backend;
  late FeedbackRepository feedback;
  late CommentRepository repo;
  late List<CommentList> published;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    feedback = backend.repository();
    repo = backend.commentRepository(feedback);
    published = [];
    repo.commentsStream.listen(published.add);
  });

  group('CommentQuery', () {
    test('sends only what differs from the default, in a fixed order', () {
      expect(const CommentQuery().toQueryParameters(), isEmpty);
      expect(
        const CommentQuery(
          sort: CommentSort.replies,
          filters: {CommentFilter.admin, CommentFilter.mine},
          search: 'scan',
        ).toQueryParameters(),
        {'sort': 'replies', 'filter': 'mine,admin', 'q': 'scan'},
      );
    });

    test('a filter or search narrows the list; a sort does not', () {
      expect(const CommentQuery(sort: CommentSort.oldest).narrows, isFalse);
      expect(const CommentQuery(filters: {CommentFilter.mine}).narrows, isTrue);
      expect(const CommentQuery(search: 'x').narrows, isTrue);
    });
  });

  test('loads comments with their replies and publishes them', () async {
    backend.answerAt(
      'GET',
      _comments,
      commentPageJson([
        commentJson(2, replies: [commentJson(5, parentId: 2)]),
        commentJson(1),
      ]),
    );

    final page = await repo.getComments(3);
    await pumpEventQueue();

    expect(_ids(page.items), [2, 1]);
    expect(page.items.first.replies.single.parentId, 2);
    expect(published.single.number, 3);
  });

  test('a second visit is served from memory and refreshed behind it', () async {
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    await repo.getComments(3);
    await pumpEventQueue();
    published.clear();
    backend.answerAt('GET', _comments, commentPageJson([commentJson(2), commentJson(1)]));

    final page = await repo.getComments(3);
    await pumpEventQueue();

    expect(_ids(page.items), [1]);
    expect(published.map((l) => _ids(l.page.items)), [
      [1],
      [2, 1],
    ]);
  });

  test('sends the query and pages on with the cursor, without repeats', () async {
    const query = CommentQuery(sort: CommentSort.oldest);
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1), commentJson(2)], nextCursor: 'c1'));
    await repo.getComments(3, query: query);
    backend.answerAt('GET', _comments, commentPageJson([commentJson(2), commentJson(3)]));

    await repo.loadMore(3, query: query);
    await pumpEventQueue();

    expect(backend.requests.first.url.queryParameters['sort'], 'oldest');
    expect(backend.requests.last.url.queryParameters['cursor'], 'c1');
    expect(_ids(published.last.page.items), [1, 2, 3]);
  });

  test('a failed load keeps what is in memory; pull-to-refresh throws', () async {
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    await repo.getComments(3);

    backend.failAt('GET', _comments);
    await repo.getComments(3, query: const CommentQuery());
    await pumpEventQueue();
    backend.failAt('GET', _comments);
    await expectLater(repo.getComments(3, forceRefresh: true), throwsA(isA<AppError>()));
  });

  test('a new comment goes on top and updates the feedback count everywhere', () async {
    final counts = <int>[];
    feedback.feedbackListStream.listen((l) => counts.add(l.page.items.single.commentCount));
    backend.answer(pageJson([3]));
    await feedback.getFeedbackList();
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    await repo.getComments(3);
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    await repo.getComments(3, query: const CommentQuery(sort: CommentSort.oldest));
    backend.answerAt('POST', _comments, {
      'comment': commentJson(9, text: 'New', isMine: true),
      'feedback': feedbackJson(3, commentCount: 2),
    }, status: 201);

    final comment = await repo.createComment(3, 'New');
    await pumpEventQueue();

    expect(comment.id, 9);
    expect(jsonDecode(backend.requests.last.body), {'text': 'New'});
    expect(_ids(published.last.page.items), [9, 1]);
    expect(published.last.query, const CommentQuery());
    expect(counts.last, 2);
    // The oldest-first list was dropped and loads again when shown.
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1), commentJson(9)]));
    await repo.getComments(3, query: const CommentQuery(sort: CommentSort.oldest));
    expect(backend.requests.last.method, 'GET');
  });

  test('a reply goes at the end of its thread in every list', () async {
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1, replies: [commentJson(4, parentId: 1)])]));
    await repo.getComments(3);
    backend.answerAt('POST', _comments, {
      'comment': commentJson(8, parentId: 1, isMine: true),
      'feedback': feedbackJson(3, commentCount: 3),
    }, status: 201);

    await repo.createComment(3, 'Reply', parentId: 1);
    await pumpEventQueue();

    expect(jsonDecode(backend.requests.last.body), {'text': 'Reply', 'parentId': 1});
    final thread = published.last.page.items.single;
    expect(_ids(thread.replies), [4, 8]);
    expect(thread.replyCount, 2);
  });

  test('an edit replaces the comment where it is', () async {
    backend.answerAt(
      'GET',
      _comments,
      commentPageJson([commentJson(1, replies: [commentJson(4, parentId: 1, isMine: true)])]),
    );
    final page = await repo.getComments(3);
    final reply = page.items.single.replies.single;
    backend.answerAt('PATCH', '/v1/comments/4', {
      'comment': commentJson(4, parentId: 1, isMine: true, text: 'Fixed', edited: true),
    });

    await repo.editComment(3, reply, 'Fixed');
    await pumpEventQueue();

    expect(jsonDecode(backend.requests.last.body), {'text': 'Fixed'});
    final edited = published.last.page.items.single.replies.single;
    expect((edited.text, edited.edited), ('Fixed', true));
  });

  group('delete', () {
    Future<List<FeedbackComment>> load(List<Map<String, dynamic>> comments) async {
      backend.answerAt('GET', _comments, commentPageJson(comments));
      return (await repo.getComments(3)).items;
    }

    void answerDelete(int id, {int count = 0}) =>
        backend.answerAt('DELETE', '/v1/comments/$id', {'feedback': feedbackJson(3, commentCount: count)});

    test('removes a comment without replies', () async {
      final items = await load([commentJson(2, isMine: true), commentJson(1)]);
      answerDelete(2, count: 1);

      await repo.deleteComment(3, items.first);
      await pumpEventQueue();

      expect(_ids(published.last.page.items), [1]);
    });

    test('keeps a comment with replies as a placeholder', () async {
      final items = await load([
        commentJson(1, isMine: true, replies: [commentJson(4, parentId: 1)]),
      ]);
      answerDelete(1, count: 1);

      await repo.deleteComment(3, items.single);
      await pumpEventQueue();

      final placeholder = published.last.page.items.single;
      expect((placeholder.deleted, placeholder.text, placeholder.isMine), (true, '', false));
      expect(_ids(placeholder.replies), [4]);
    });

    test("removes a placeholder with its last reply", () async {
      final items = await load([
        commentJson(1, deleted: true, replies: [commentJson(4, parentId: 1, isMine: true)]),
      ]);
      answerDelete(4);

      await repo.deleteComment(3, items.single.replies.single);
      await pumpEventQueue();

      expect(published.last.page.items, isEmpty);
    });

    test('removes a reply and keeps its parent', () async {
      final items = await load([
        commentJson(1, replies: [commentJson(4, parentId: 1, isMine: true)]),
      ]);
      answerDelete(4, count: 1);

      await repo.deleteComment(3, items.single.replies.single);
      await pumpEventQueue();

      final thread = published.last.page.items.single;
      expect((thread.id, thread.replies.length, thread.replyCount), (1, 0, 0));
    });
  });

  test('a response the app cannot read is an AppError', () async {
    backend.answerAt('GET', _comments, {'items': 'nope'});

    await expectLater(
      repo.getComments(3),
      throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.network)),
    );
  });

  test('keeps comments of the 10 most recently opened feedback', () async {
    for (var n = 1; n <= CommentRepository.maxCachedFeedback + 1; n++) {
      backend.answerAt('GET', '/v1/feedback/$n/comments', commentPageJson([commentJson(n)]));
      await repo.getComments(n);
    }
    final requests = backend.requests.length;

    // #11 is still in memory: served at once, refreshed behind it.
    backend.answerAt('GET', '/v1/feedback/11/comments', commentPageJson([commentJson(11)]));
    unawaited(repo.getComments(11));
    await pumpEventQueue();
    // #1 was dropped: the request is the only source.
    final gate = Completer<void>();
    backend.answerAtLater('GET', '/v1/feedback/1/comments', gate.future, commentPageJson([commentJson(1)]));
    var done = false;
    unawaited(repo.getComments(1).then((_) => done = true));
    await pumpEventQueue();
    expect(done, isFalse);
    gate.complete();
    await pumpEventQueue();
    expect(done, isTrue);
    expect(backend.requests.length, requests + 2);
  });
}
