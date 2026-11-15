import 'dart:convert';

import 'package:community_package/src/core/navigation/community_navigator.dart';
import 'package:community_package/src/core/widgets/comment_query_menus.dart';
import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/core/widgets/inner_shadow.dart';
import 'package:community_package/src/features/feedback_detail/presentation/comment_thread.dart';
import 'package:community_package/src/features/feedback_detail/presentation/edit_comment_sheet.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_controller.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_screen.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _item = '/v1/feedback/3';
const _comments = '/v1/feedback/3/comments';

/// A widget whose own Semantics carries [label], such as a replies chip.
Finder _semantics(String label) =>
    find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

void main() {
  late FakeBackend backend;

  final editButton = find.byTooltip('Edit comment');
  final addButton = find.byTooltip('Write a comment');
  final sendButton = find.byTooltip('Send');
  final showReplies = _semantics('Show 2 replies');
  final hideReplies = _semantics('Hide replies');
  final replyPlus = find.byTooltip('Reply');

  /// A thread (#2, the user's, with two replies, one of them the user's)
  /// and a plain comment (#1).
  List<Map<String, dynamic>> defaultComments() => [
    commentJson(
      2,
      text: 'Any update?',
      isMine: true,
      day: 2,
      replies: [
        commentJson(5, parentId: 2, text: 'Working on it', day: 3),
        commentJson(6, parentId: 2, text: 'Thanks!', isMine: true, edited: true, day: 4),
      ],
    ),
    commentJson(1, text: 'Me too'),
  ];

  Future<void> open(
    WidgetTester tester, {
    Map<String, dynamic>? item,
    List<Map<String, dynamic>>? comments,
    ThemeData? theme,
    bool rulesAgreed = true,
  }) async {
    SharedPreferences.setMockInitialValues({if (rulesAgreed) IdentityRepository.rulesAgreedKey: true});
    backend.answerAt('GET', _item, item ?? feedbackJson(3, status: 'in_progress', commentCount: 4));
    backend.answerAt('GET', _comments, commentPageJson(comments ?? defaultComments()));
    final feedback = backend.repository();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.dark(),
        home: FeedbackDetailScreen(
          number: 3,
          createController: () => FeedbackDetailController(
            number: 3,
            feedback: feedback,
            comments: backend.commentRepository(feedback),
          ),
          postGate: PostGate(identity: IdentityRepository(FakeAnonIdSource(id: FakeAnonIdSource.createdId))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> lastBody(String method) =>
      jsonDecode(backend.requests.lastWhere((r) => r.method == method).body) as Map<String, dynamic>;

  setUp(() {
    backend = FakeBackend();
  });

  group('header', () {
    testWidgets('shows the status when one is set', (tester) async {
      await open(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('in progress')), findsOneWidget);
    });

    // specs.md §2: the status is 18 Medium after a 20 px 💪.
    testWidgets('the status title is Medium with a 20 px emoji', (tester) async {
      await open(tester);

      final title = tester.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.text('in progress')));
      expect(title.style?.fontWeight, FontWeight.w500);
      expect(tester.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.text('💪'))).style?.fontSize, 20);
    });

    // Settings-6: the comments start 66 under the card.
    testWidgets('card, toolbar and comments are spaced like Figma', (tester) async {
      await open(tester);

      final card = tester.getRect(find.byType(FeedbackCard));
      final thread = tester.getRect(find.byType(CommentThread).first);
      expect(thread.top - card.bottom, 66);
      expect(tester.getCenter(find.byTooltip('Sort')).dy - card.bottom, 32);
    });

    testWidgets('shows the type while there is no status', (tester) async {
      await open(tester, item: feedbackJson(3, type: 'problem'));

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Problem')), findsOneWidget);
    });
  });

  testWidgets('shows the card and the comments with replies closed', (tester) async {
    await open(tester);

    expect(find.byType(FeedbackCard), findsOneWidget);
    expect(find.text('Any update?'), findsOneWidget);
    expect(find.text('Me too'), findsOneWidget);
    expect(find.text('Working on it'), findsNothing);
    expect(showReplies, findsOneWidget);
    // The comment without replies: its chip opens the reply field.
    expect(_semantics('Reply'), findsOneWidget);
  });

  testWidgets('the replies chip opens the thread (▲) with a +, and closes it (▼)', (tester) async {
    await open(tester);

    await tapAndSettle(tester, showReplies);
    expect(find.text('Working on it'), findsOneWidget);
    expect(find.text('Thanks!'), findsOneWidget);
    expect(hideReplies, findsOneWidget);
    expect(replyPlus, findsOneWidget);
    expect(find.widgetWithText(TextField, 'new Comment...'), findsNothing);

    await tapAndSettle(tester, hideReplies);
    expect(find.text('Working on it'), findsNothing);
  });

  // Settings-6, 11 Nov: the + under a thread turns into a focused reply
  // field, and back into the + when the field is left empty.
  testWidgets('the + shows a focused reply field; left empty it turns back', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);

    await tapAndSettle(tester, replyPlus);
    final field = find.widgetWithText(TextField, 'new Comment...');
    expect(field, findsOneWidget);
    expect(replyPlus, findsNothing);
    expect(tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText))).focusNode.hasFocus, isTrue);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(field, findsNothing);
    expect(replyPlus, findsOneWidget);
  });

  // Flutter keeps the focus on a touch outside a field on phones
  // (EditableText's tap-outside action), so the field closes it itself.
  testWidgets('a tap outside the empty reply field turns it back into the +', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);
    await tapAndSettle(tester, replyPlus);
    expect(find.widgetWithText(TextField, 'new Comment...'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(AppBar)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'new Comment...'), findsNothing);
    expect(replyPlus, findsOneWidget);
  });

  testWidgets('a reply field with text stays when it loses focus', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);
    await tapAndSettle(tester, replyPlus);

    await tester.enterText(find.widgetWithText(TextField, 'new Comment...'), 'Half a thought');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Half a thought'), findsOneWidget);
    expect(replyPlus, findsNothing);
  });

  testWidgets('the chip of a comment without replies opens the reply field at once', (tester) async {
    await open(tester);

    await tapAndSettle(tester, _semantics('Reply'));

    expect(find.widgetWithText(TextField, 'new Comment...'), findsOneWidget);
  });

  testWidgets('comment chips and dividers look like Figma', (tester) async {
    await open(tester, theme: ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000))));
    await tapAndSettle(tester, showReplies);

    final thread = tester.getRect(find.byType(CommentThread).first);
    final chip = tester.getRect(find.descendant(of: find.byType(CommentThread).first, matching: find.byType(InnerShadow)));
    expect(chip.left - thread.left, 10);
    expect(chip.height, 26);
    expect(chip.width, greaterThanOrEqualTo(65));
    final divider = tester.widgetList<Divider>(find.byType(Divider)).first;
    expect((divider.indent, divider.endIndent, divider.color?.toARGB32()), (11.0, 15.0, 0xFF5C5C5C));
    final firstDivider = tester.getRect(find.byType(Divider).first);
    expect(firstDivider.top - chip.bottom, 4);
    expect(tester.getSize(find.ancestor(of: replyPlus, matching: find.byType(SizedBox)).first).height, 56);
    final reply = tester.widget<Text>(find.text('Working on it'));
    expect(reply.style?.fontWeight, FontWeight.w300);
  });

  testWidgets('only the user\'s own comments have ✏️; edited ones say so', (tester) async {
    await open(tester);
    expect(editButton, findsOneWidget);

    await tapAndSettle(tester, showReplies);
    expect(editButton, findsNWidgets(2));
    expect(find.textContaining('· edited'), findsOneWidget);
  });

  testWidgets('a deleted comment with replies shows "Comment deleted"', (tester) async {
    await open(
      tester,
      comments: [
        commentJson(2, deleted: true, replies: [commentJson(5, parentId: 2)]),
      ],
    );

    expect(find.text('Comment deleted'), findsOneWidget);
    expect(editButton, findsNothing);
  });

  testWidgets('+ opens the new comment field; sending posts it on top and updates the count', (tester) async {
    await open(tester);
    expect(find.widgetWithText(TextField, 'new Comment...'), findsNothing);

    await tapAndSettle(tester, addButton);
    expect(find.widgetWithText(TextField, 'new Comment...'), findsOneWidget);
    expect(sendButton, findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'new Comment...'), '  Great idea  ');
    await tester.pump();
    backend.answerAt('POST', _comments, {
      'comment': commentJson(9, text: 'Great idea', isMine: true, day: 5),
      'feedback': feedbackJson(3, status: 'in_progress', commentCount: 5),
    }, status: 201);
    await tapAndSettle(tester, sendButton);

    expect(lastBody('POST'), {'text': 'Great idea'});
    expect(find.text('Great idea'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Great idea')).dy,
      lessThan(tester.getTopLeft(find.text('Any update?')).dy),
    );
    expect(find.descendant(of: find.byType(FeedbackCard), matching: find.text('5')), findsOneWidget);
    expect(find.widgetWithText(TextField, 'new Comment...'), findsNothing);
  });

  testWidgets('the first comment asks for the rules; declining sends nothing', (tester) async {
    await open(tester, rulesAgreed: false);
    await tapAndSettle(tester, addButton);
    await tester.enterText(find.widgetWithText(TextField, 'new Comment...'), 'Hello');
    await tester.pump();

    await tapAndSettle(tester, sendButton);
    expect(find.byType(RulesSheet), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(backend.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('a reply is sent with its thread and shows at the end of it', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);
    await tapAndSettle(tester, replyPlus);

    await tester.enterText(find.widgetWithText(TextField, 'new Comment...'), 'Me as well');
    await tester.pump();
    backend.answerAt('POST', _comments, {
      'comment': commentJson(10, parentId: 2, text: 'Me as well', isMine: true, day: 5),
      'feedback': feedbackJson(3, status: 'in_progress', commentCount: 5),
    }, status: 201);
    await tapAndSettle(tester, sendButton);

    expect(lastBody('POST'), {'text': 'Me as well', 'parentId': 2});
    expect(
      tester.getTopLeft(find.text('Me as well')).dy,
      greaterThan(tester.getTopLeft(find.text('Thanks!')).dy),
    );
    // Sent: the field turns back into the +.
    expect(replyPlus, findsOneWidget);
  });

  testWidgets('Edit Comment saves the new text', (tester) async {
    await open(tester);

    await tapAndSettle(tester, editButton);
    expect(find.byType(EditCommentSheet), findsOneWidget);
    expect(find.text('edit Comment'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(EditCommentSheet), matching: find.byType(TextField)),
      'Any news?',
    );
    backend.answerAt('PATCH', '/v1/comments/2', {
      'comment': commentJson(2, text: 'Any news?', isMine: true, edited: true, day: 2, replies: [
        commentJson(5, parentId: 2, text: 'Working on it', day: 3),
        commentJson(6, parentId: 2, text: 'Thanks!', isMine: true, edited: true, day: 4),
      ]),
    });
    await tapAndSettle(tester, find.byTooltip('save'));

    expect(lastBody('PATCH'), {'text': 'Any news?'});
    expect(find.byType(EditCommentSheet), findsNothing);
    expect(find.text('Any news?'), findsOneWidget);
    expect(find.textContaining('· edited'), findsOneWidget);
  });

  // Settings-12: 70% scrim, a #404040 field border, a 43×42 🗑 with the
  // outline trash.
  testWidgets('Edit Comment looks like Figma', (tester) async {
    await open(tester, theme: ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000))));
    await tapAndSettle(tester, editButton);

    final barrier = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier)).last;
    expect(barrier.color, const Color(0xB3000000));
    final field = tester.widget<TextField>(find.descendant(of: find.byType(EditCommentSheet), matching: find.byType(TextField)));
    expect((field.decoration!.enabledBorder! as OutlineInputBorder).borderSide.color.toARGB32(), 0xFF404040);
    final delete = find.byTooltip('delete');
    expect(tester.getSize(find.descendant(of: delete, matching: find.byType(InkWell))), const Size(43, 42));
    expect(find.descendant(of: delete, matching: find.byType(SvgPicture)), findsOneWidget);
  });

  testWidgets('Edit Comment: the 🗑 takes taps in 44 × 44 and the buttons stay in place', (tester) async {
    await open(tester);
    await tapAndSettle(tester, editButton);

    Finder inSheet(Finder f) => find.descendant(of: find.byType(EditCommentSheet), matching: f);
    final delete = inSheet(find.byTooltip('delete'));
    expect(tester.getSize(delete), const Size(44, 44));
    final box = tester.getRect(find.descendant(of: delete, matching: find.byType(InkWell)));
    expect(box.left - tester.getRect(inSheet(find.byTooltip('cancel'))).right, 30);
    expect(tester.getRect(inSheet(find.byTooltip('save'))).left - box.right, 30);

    // Just above the red box still counts.
    await tester.tapAt(Offset(box.center.dx, box.top - 0.5));
    await tester.pumpAndSettle();
    expect(find.text('Delete this comment? Its replies stay.'), findsOneWidget);
  });

  testWidgets('a comment ✏️ takes taps 48 wide and stays in its Figma place', (tester) async {
    await open(tester);

    final button = editButton.first;
    final rect = tester.getRect(button);
    expect(rect.size, const Size(48, 32));
    // The ✏️ is centred on the 40 px place at the row's end, as before.
    expect(tester.getCenter(find.descendant(of: button, matching: find.text('✏️'))).dx, rect.right - 20);

    await tester.tapAt(Offset(rect.left + 3, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.byType(EditCommentSheet), findsOneWidget);
  });

  testWidgets('the replies chip takes taps in the space around it', (tester) async {
    await open(tester);

    final chip = tester.getRect(find.descendant(of: showReplies, matching: find.byType(InnerShadow)));
    expect(tester.getSize(showReplies).height, 42);
    expect(chip.size.height, 26);

    // 4 px above the chip, in the gap under the text.
    await tester.tapAt(Offset(chip.center.dx, chip.top - 4));
    await tester.pumpAndSettle();
    expect(hideReplies, findsOneWidget);
    // Open, the divider is 4 under the chip.
    expect(tester.getSize(hideReplies).height, 36);
  });

  testWidgets('Edit Comment: 🗑 asks first, then leaves a placeholder above the replies', (tester) async {
    await open(tester);
    await tapAndSettle(tester, editButton);

    await tapAndSettle(tester, find.byTooltip('delete'));
    expect(find.text('Delete this comment? Its replies stay.'), findsOneWidget);
    await tapAndSettle(tester, find.text('keep'));
    expect(find.byType(EditCommentSheet), findsOneWidget);
    expect(backend.requests.where((r) => r.method == 'DELETE'), isEmpty);

    backend.answerAt('DELETE', '/v1/comments/2', {
      'feedback': feedbackJson(3, status: 'in_progress', commentCount: 3),
    });
    await tapAndSettle(tester, find.byTooltip('delete'));
    await tapAndSettle(tester, find.text('delete'));

    expect(find.byType(EditCommentSheet), findsNothing);
    expect(find.text('Comment deleted'), findsOneWidget);
    expect(find.text('Any update?'), findsNothing);
    expect(find.descendant(of: find.byType(FeedbackCard), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('sort and filter menus reload the comments', (tester) async {
    await open(tester);

    await tapAndSettle(tester, find.byTooltip('Sort'));
    expect(find.byType(CommentSortMenu), findsOneWidget);
    for (final label in ['Newest', 'Oldest', 'Most replies']) {
      expect(find.text(label), findsOneWidget);
    }
    backend.answerAt('GET', _comments, commentPageJson(defaultComments()));
    await tapAndSettle(tester, find.text('Most replies'));
    expect(backend.requests.last.url.queryParameters['sort'], 'replies');

    await tapAndSettle(tester, find.byTooltip('Filter'));
    expect(find.byType(CommentFilterMenu), findsOneWidget);
    backend.answerAt('GET', _comments, commentPageJson([commentJson(1)]));
    await tapAndSettle(tester, find.text('Admin'));
    expect(backend.requests.last.url.queryParameters['filter'], 'admin');
  });

  testWidgets('no comments shows an empty message', (tester) async {
    await open(tester, comments: []);

    expect(find.text('No comments yet'), findsOneWidget);
  });

  testWidgets('feedback that no longer exists says so', (tester) async {
    SharedPreferences.setMockInitialValues({});
    backend.failAt('GET', _item, status: 404, code: 'not_found');
    backend.failAt('GET', _comments, status: 404, code: 'not_found');
    final feedback = backend.repository();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackDetailScreen(
          number: 3,
          createController: () => FeedbackDetailController(
            number: 3,
            feedback: feedback,
            comments: backend.commentRepository(feedback),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This feedback no longer exists.'), findsOneWidget);
  });

  testWidgets('tapping a card in All Feedback opens its detail by number', (tester) async {
    SharedPreferences.setMockInitialValues({});
    backend.answer(pageJson([3, 2, 1]));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => settings.name == CommunityRoutes.feedbackDetail
            ? MaterialPageRoute<void>(builder: (_) => Text('detail ${settings.arguments}'))
            : null,
        home: FeedbackListScreen(createController: () => FeedbackListController(backend.repository())),
      ),
    );
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Feedback 2'));

    expect(find.text('detail 2'), findsOneWidget);
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow on a small phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, theme: theme);
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, showReplies);
      await tapAndSettle(tester, replyPlus);
      await tapAndSettle(tester, addButton);
      await tester.enterText(find.widgetWithText(TextField, 'new Comment...').first, 'A long comment ' * 10);
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, editButton.first);
      expect(tester.takeException(), isNull);
    });
  }
}
