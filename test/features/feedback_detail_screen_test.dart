import 'dart:convert';

import 'package:community_package/src/core/navigation/community_navigator.dart';
import 'package:community_package/src/core/widgets/comment_query_menus.dart';
import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/features/feedback_detail/presentation/comment_thread.dart';
import 'package:community_package/src/features/feedback_detail/presentation/edit_comment_sheet.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_controller.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_screen.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:flutter/material.dart';
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
  final replyPlus = find.widgetWithText(TextButton, 'Reply');

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
    // Lay out at the new scroll offset before tapping.
    await tester.pump();
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

    // Design refresh: titles 17 SemiBold, after a 20 px 💪.
    testWidgets('the status title is 17 SemiBold with a 20 px emoji', (tester) async {
      await open(tester);

      final title = tester.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.text('in progress')));
      expect((title.style?.fontSize, title.style?.fontWeight), (17.0, FontWeight.w600));
      expect(tester.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.text('💪'))).style?.fontSize, 20);
    });

    // Design refresh: 8 around the 48 px toolbar, 12 between comments,
    // 16 from the screen's edges.
    testWidgets('card, toolbar and comments sit on the 8 pt grid', (tester) async {
      await open(tester);

      final card = tester.getRect(find.byType(FeedbackCard));
      final threads = find.byType(CommentThread);
      final thread = tester.getRect(threads.first);
      expect(card.left, 16);
      expect(thread.top - card.bottom, 64);
      expect(tester.getCenter(find.byTooltip('Sort')).dy - card.bottom, 32);
      expect(tester.getSize(find.byTooltip('Sort')), const Size(48, 48));
      expect(tester.getRect(threads.at(1)).top - thread.bottom, 12);
    });

    // Johannes read filter_list as a second sort icon: filter is a funnel.
    testWidgets('toolbar: a funnel for filter, every icon 26 in a 48 button', (tester) async {
      await open(tester);

      expect(find.descendant(of: find.byTooltip('Filter'), matching: find.byIcon(Icons.filter_alt_outlined)), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsNothing);
      expect(find.descendant(of: find.byTooltip('Sort'), matching: find.byIcon(Icons.sort_rounded)), findsOneWidget);
      for (final tooltip in ['Sort', 'Filter', 'Search', 'Write a comment']) {
        final button = find.byTooltip(tooltip);
        expect(tester.getSize(button), const Size(48, 48), reason: tooltip);
        expect(tester.getSize(find.descendant(of: button, matching: find.byType(Icon))), const Size(26, 26), reason: tooltip);
      }
    });

    // Asad, 22 Nov: the heart's number sat about 2 pt below the comment count.
    for (final (name, costCents, status) in [
      ('status and cost', 5000, 'in_progress'),
      ('no status, no cost', null, null),
    ]) {
      testWidgets('card bottom row shares one text baseline ($name)', (tester) async {
        await open(tester, item: feedbackJson(3, status: status, commentCount: 4, reactionCount: 7, costCents: costCents));

        final card = find.byType(FeedbackCard);
        double baseline(bool Function(String) match) {
          final box = tester.renderObject<RenderBox>(
            find.descendant(of: card, matching: find.byWidgetPredicate((w) => w is RichText && match(w.text.toPlainText()))).first,
          );
          return box.localToGlobal(Offset(0, box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!)).dy;
        }

        final reference = baseline((t) => t == '4');
        expect(baseline((t) => t.startsWith('❤️')), closeTo(reference, 0.5));
        if (status != null) expect(baseline((t) => t == 'in progress'), closeTo(reference, 0.5));
        if (costCents != null) expect(baseline((t) => t.startsWith('💰')), closeTo(reference, 0.5));
        expect(tester.takeException(), isNull);
      });
    }

    // Asad, 22 Nov: with a cost, the counts and heart drifted left toward
    // the status. Status left, heart pill at the right edge, always.
    for (final (name, costCents, status) in [
      ('status and cost', 70000, 'planned'),
      ('cost only', 70000, null),
      ('status only', null, 'planned'),
      ('neither', null, null),
    ]) {
      testWidgets('card: status left, heart at the right edge ($name)', (tester) async {
        await open(tester, item: feedbackJson(3, status: status, commentCount: 1, reactionCount: 10, costCents: costCents));

        final cardRect = tester.getRect(find.byType(FeedbackCard));
        final heart = find.descendant(
          of: find.byType(FeedbackCard),
          matching: find.byWidgetPredicate((w) => w is AnimatedContainer),
        );
        // Card padding 4 on the right, content padding 12: 16 in.
        expect(cardRect.right - tester.getRect(heart).right, closeTo(16, 0.5));
        if (status != null) {
          expect(tester.getRect(find.descendant(of: find.byType(FeedbackCard), matching: find.text('planned'))).left - cardRect.left, lessThan(60));
        }
      });
    }

    // Johannes, 22 Nov: the cost sits next to the status, not next to the
    // comment count.
    for (final (name, status) in [('with a status', 'planned'), ('without a status', null)]) {
      testWidgets('card: the cost follows the status on the left ($name)', (tester) async {
        await open(tester, item: feedbackJson(3, status: status, commentCount: 1, reactionCount: 10, costCents: 70000));

        final card = find.byType(FeedbackCard);
        final cardRect = tester.getRect(card);
        final cost = tester.getRect(
          find.descendant(of: card, matching: find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().startsWith('💰'))),
        );
        final comments = tester.getRect(find.descendant(of: card, matching: find.text('💬')));
        if (status != null) {
          final statusRight = tester.getRect(find.descendant(of: card, matching: find.text('planned'))).right;
          expect(cost.left - statusRight, closeTo(12, 0.5));
        } else {
          expect(cost.left - cardRect.left, lessThan(30));
        }
        // A clear gap to the counts, which stay at the right.
        expect(comments.left - cost.right, greaterThan(40));
      });
    }

    testWidgets('card: 💬, ❤️, 💰 and 💪 are 20 with 16 counts', (tester) async {
      await open(tester, item: feedbackJson(3, status: 'in_progress', commentCount: 4, costCents: 5000));

      final card = find.byType(FeedbackCard);
      for (final emoji in ['💬', '💪']) {
        final text = tester.widget<Text>(find.descendant(of: card, matching: find.text(emoji)));
        expect(text.style?.fontSize, 20, reason: emoji);
      }
      expect(tester.widget<Text>(find.descendant(of: card, matching: find.text('4'))).style?.fontSize, 16);
      expect(tester.widget<Text>(find.descendant(of: card, matching: find.text('in progress'))).style?.fontSize, 16);
      final heart = tester.widget<RichText>(
        find.descendant(of: card, matching: find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().startsWith('❤️'))),
      );
      // Text.rich wraps the spans in one with the text style.
      double? sizeOf(String text) {
        double? size;
        heart.text.visitChildren((span) {
          if (span is TextSpan && span.text != null && span.text!.contains(text)) {
            size = span.style?.fontSize;
            return false;
          }
          return true;
        });
        return size;
      }
      expect(heart.text.style?.fontSize, 16);
      expect(sizeOf('❤️'), 20);
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
    expect(find.widgetWithText(TextField, 'New comment…'), findsNothing);

    await tapAndSettle(tester, hideReplies);
    expect(find.text('Working on it'), findsNothing);
  });

  // Settings-6, 11 Nov: the + under a thread turns into a focused reply
  // field, and back into the + when the field is left empty.
  testWidgets('the + shows a focused reply field; left empty it turns back', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);

    await tapAndSettle(tester, replyPlus);
    final field = find.widgetWithText(TextField, 'New comment…');
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
    expect(find.widgetWithText(TextField, 'New comment…'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(AppBar)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'New comment…'), findsNothing);
    expect(replyPlus, findsOneWidget);
  });

  testWidgets('a reply field with text stays when it loses focus', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);
    await tapAndSettle(tester, replyPlus);

    await tester.enterText(find.widgetWithText(TextField, 'New comment…'), 'Half a thought');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Half a thought'), findsOneWidget);
    expect(replyPlus, findsNothing);
  });

  testWidgets('the chip of a comment without replies opens the reply field at once', (tester) async {
    await open(tester);

    await tapAndSettle(tester, _semantics('Reply'));

    expect(find.widgetWithText(TextField, 'New comment…'), findsOneWidget);
  });

  testWidgets('comment cards, the replies chip and dividers use the refreshed look', (tester) async {
    await open(tester, theme: ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000))));

    final threadFinder = find.byType(CommentThread).first;
    final context = tester.element(threadFinder);
    final material = tester.widget<Material>(find.descendant(of: threadFinder, matching: find.byType(Material)).first);
    expect(material.color, RefreshColors.card(context));
    expect(material.color, isNot(const Color(0xFF000000)));
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(find.descendant(of: showReplies, matching: find.text('2 replies')), findsOneWidget);

    await tapAndSettle(tester, showReplies);
    final divider = tester.widgetList<Divider>(find.byType(Divider)).first;
    expect((divider.indent, divider.endIndent), (16.0, 16.0));
    expect(tester.getSize(replyPlus).height, 48);
    final reply = tester.widget<Text>(find.text('Working on it'));
    expect((reply.style?.fontSize, reply.style?.height), (15.0, 1.4));
  });

  testWidgets('the replies open and close with an animation', (tester) async {
    await open(tester);

    final closedHeight = tester.getSize(find.byType(CommentThread).first).height;
    await tester.tap(showReplies);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midHeight = tester.getSize(find.byType(CommentThread).first).height;
    await tester.pumpAndSettle();
    final openHeight = tester.getSize(find.byType(CommentThread).first).height;
    expect(midHeight, greaterThan(closedHeight));
    expect(midHeight, lessThan(openHeight));
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
    expect(find.widgetWithText(TextField, 'New comment…'), findsNothing);

    await tapAndSettle(tester, addButton);
    expect(find.widgetWithText(TextField, 'New comment…'), findsOneWidget);
    expect(sendButton, findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'New comment…'), '  Great idea  ');
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
    expect(find.widgetWithText(TextField, 'New comment…'), findsNothing);
  });

  testWidgets('the first comment asks for the rules; declining sends nothing', (tester) async {
    await open(tester, rulesAgreed: false);
    await tapAndSettle(tester, addButton);
    await tester.enterText(find.widgetWithText(TextField, 'New comment…'), 'Hello');
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

    await tester.enterText(find.widgetWithText(TextField, 'New comment…'), 'Me as well');
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
    expect(find.text('Edit comment'), findsOneWidget);
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
    await tapAndSettle(tester, find.text('Save'));

    expect(lastBody('PATCH'), {'text': 'Any news?'});
    expect(find.byType(EditCommentSheet), findsNothing);
    expect(find.text('Any news?'), findsOneWidget);
    expect(find.textContaining('· edited'), findsOneWidget);
  });

  // Design refresh: a sheet on the sheet layer with a 24 top radius, a
  // filled field without a border until focused, Save filled with a check.
  testWidgets('Edit Comment uses the refreshed sheet, field and buttons', (tester) async {
    await open(tester, theme: ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000))));
    await tapAndSettle(tester, editButton);

    final sheetContext = tester.element(find.byType(EditCommentSheet));
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, RefreshColors.sheet(sheetContext));
    expect((sheet.shape! as RoundedRectangleBorder).borderRadius, const BorderRadius.vertical(top: Radius.circular(24)));
    final field = tester.widget<TextField>(find.descendant(of: find.byType(EditCommentSheet), matching: find.byType(TextField)));
    final decoration = field.decoration!;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, isNot(sheet.backgroundColor));
    expect((decoration.enabledBorder! as OutlineInputBorder).borderSide, BorderSide.none);
    final focused = (decoration.focusedBorder! as OutlineInputBorder).borderSide;
    expect((focused.color, focused.width), (Theme.of(sheetContext).colorScheme.primary, 1.5));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.getSize(find.ancestor(of: find.text('Save'), matching: find.byType(ConstrainedBox)).first).height, 48);
    final deleteText = tester.widget<Text>(find.text('Delete'));
    final deleteColor = DefaultTextStyle.of(tester.element(find.text('Delete'))).style.color ?? deleteText.style?.color;
    // The error colour, raised to 4.5:1 on its tonal background.
    final scheme = Theme.of(sheetContext).colorScheme;
    expect(deleteColor, RefreshColors.readable(scheme.error, scheme.onSurface, RefreshColors.errorTonal(sheetContext), 4.5));
    expect(RefreshColors.contrast(deleteColor!, RefreshColors.errorTonal(sheetContext)), greaterThanOrEqualTo(4.5));
  });

  testWidgets('Edit Comment: Delete sits on its own row under Save, 48 high', (tester) async {
    await open(tester);
    await tapAndSettle(tester, editButton);

    final save = tester.getRect(find.text('Save'));
    final cancel = tester.getRect(find.text('Cancel'));
    final delete = tester.getRect(find.text('Delete'));
    expect(cancel.center.dy, save.center.dy);
    expect(cancel.left, lessThan(save.left));
    expect(delete.top, greaterThan(save.bottom + 16));
    final deleteButton = find.ancestor(of: find.text('Delete'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(deleteButton).height, 48);

    await tapAndSettle(tester, find.text('Delete'));
    expect(find.text('Delete this comment? Its replies stay.'), findsOneWidget);
  });

  // The destructive buttons share the two-column grid of Cancel and Save.
  testWidgets('Edit Comment: Delete alone is full width, under Cancel and Save', (tester) async {
    await open(tester);
    await tapAndSettle(tester, editButton);

    Rect rect(String label) => tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first);
    expect(rect('Delete').left, rect('Cancel').left);
    expect(rect('Delete').right, rect('Save').right);
    expect(rect('Save').left - rect('Cancel').right, 12);
  });

  testWidgets('a comment edit button is a 48 px rounded icon', (tester) async {
    await open(tester);

    final button = editButton.first;
    expect(tester.getSize(button), const Size(48, 48));
    expect(find.descendant(of: button, matching: find.byIcon(Icons.edit_outlined)), findsOneWidget);
    expect(find.text('✏️'), findsNothing);

    await tapAndSettle(tester, button);
    expect(find.byType(EditCommentSheet), findsOneWidget);
  });

  testWidgets('the Reply button has a line-style arrow, not the solid one', (tester) async {
    await open(tester);
    await tapAndSettle(tester, showReplies);

    expect(find.descendant(of: replyPlus, matching: find.byIcon(Icons.subdirectory_arrow_right_rounded)), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsNothing);
  });

  // Ages and labels of different lengths must not move the button.
  testWidgets('every comment edit button ends 4 from its card\'s right edge', (tester) async {
    await open(
      tester,
      comments: [
        commentJson(
          2,
          text: 'Any update?',
          isMine: true,
          isAdmin: true,
          day: 2,
          replies: [commentJson(6, parentId: 2, text: 'Thanks!', isMine: true, edited: true, day: 4)],
        ),
      ],
    );
    await tapAndSettle(tester, _semantics('Show 1 reply'));

    final card = tester.getRect(find.byType(CommentThread).first);
    expect(editButton, findsNWidgets(2));
    for (final element in editButton.evaluate()) {
      final rect = tester.getRect(find.byElementPredicate((e) => e == element));
      expect(card.right - rect.right, closeTo(4, 0.5));
    }
  });

  testWidgets('the replies chip is a 40 px pill that takes taps 48 high', (tester) async {
    await open(tester);

    final pill = tester.getRect(find.descendant(of: showReplies, matching: find.byType(InkWell)));
    expect(pill.height, 40);
    expect(tester.getSize(showReplies).height, 48);

    // 3 px above the pill still counts.
    await tester.tapAt(Offset(pill.center.dx, pill.top - 3));
    await tester.pumpAndSettle();
    expect(hideReplies, findsOneWidget);
    expect(find.descendant(of: hideReplies, matching: find.text('2 replies')), findsOneWidget);
  });

  testWidgets('Edit Comment: 🗑 asks first, then leaves a placeholder above the replies', (tester) async {
    await open(tester);
    await tapAndSettle(tester, editButton);

    await tapAndSettle(tester, find.text('Delete'));
    expect(find.text('Delete this comment? Its replies stay.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Keep'));
    expect(find.byType(EditCommentSheet), findsOneWidget);
    expect(backend.requests.where((r) => r.method == 'DELETE'), isEmpty);

    backend.answerAt('DELETE', '/v1/comments/2', {
      'feedback': feedbackJson(3, status: 'in_progress', commentCount: 3),
    });
    await tapAndSettle(tester, find.text('Delete'));
    await tapAndSettle(tester, find.text('Delete').last);

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
    testWidgets('a full card bottom row fits a 320 px phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(
        tester,
        theme: theme,
        item: feedbackJson(3, status: 'in_progress', commentCount: 1234, costCents: 123456789),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow on a small phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, theme: theme);
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, showReplies);
      await tapAndSettle(tester, replyPlus);
      // Back to the top: the list builds the toolbar lazily.
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 2000), 3000);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, addButton);
      await tester.enterText(find.widgetWithText(TextField, 'New comment…').first, 'A long comment ' * 10);
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, editButton.first);
      expect(tester.takeException(), isNull);
    });
  }
}
