import 'dart:async';
import 'dart:convert';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/core/widgets/feedback_type_picker.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_screen.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:community_package/src/core/widgets/community_menu.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _config = CommunityConfig(backendUrl: 'https://example.com', appId: 'inventory');

void main() {
  late FakeBackend backend;
  late BuildContext hostContext;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });
  tearDown(CommunityPackage.reset);

  // skipOffstage: false also counts a screen hidden under another one.
  final formScreens = find.byType(NewFeedbackScreen, skipOffstage: false);
  final listScreens = find.byType(FeedbackListScreen, skipOffstage: false);
  final submit = find.widgetWithText(RefreshButton, 'Submit');
  final cancel = find.widgetWithText(RefreshButton, 'Cancel');
  final notice = find.byType(PrivacyNoticeSheet);
  final rules = find.byType(RulesSheet);

  /// The host app. [agreed] starts with a user who already agreed to the
  /// privacy notice and the rules.
  Future<void> host(WidgetTester tester, {bool agreed = false, ThemeData? theme}) async {
    if (agreed) {
      SharedPreferences.setMockInitialValues({IdentityRepository.rulesAgreedKey: true});
    }
    await CommunityPackage.init(_config);
    CommunityDependencies.register(
      _config,
      httpClient: backend.client,
      anonIdSource: FakeAnonIdSource(id: agreed ? FakeAnonIdSource.createdId : null),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            hostContext = c;
            return const Scaffold();
          },
        ),
      ),
    );
  }

  /// Settings → "Give feedback".
  Future<void> openFromSettings(WidgetTester tester, {bool agreed = false, ThemeData? theme}) async {
    await host(tester, agreed: agreed, theme: theme);
    unawaited(CommunityPackage.openNewFeedback(hostContext));
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester, {String topic = 'Improvement', String text = 'Totals'}) async {
    await tapAndSettle(tester, find.text(topic));
    await tester.enterText(find.byType(TextField), text);
    // Settle: the back handler learns about the typed text a frame later.
    await tester.pumpAndSettle();
  }

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<InkWell>(find.descendant(of: submit, matching: find.byType(InkWell))).onTap != null;

  testWidgets('openNewFeedback before init fails with a clear error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            hostContext = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(() => CommunityPackage.openNewFeedback(hostContext), throwsStateError);
  });

  testWidgets('opens one New Feedback screen with only the topic list, no topic chosen', (tester) async {
    await openFromSettings(tester);

    expect(formScreens, findsOneWidget);
    expect(listScreens, findsNothing);
    expect(find.text('New Feedback'), findsOneWidget);
    // The closed pill stays laid out under the list, hidden and untappable.
    expect(find.text('Choose Topic').hitTestable(), findsOneWidget);
    expect(find.text('Improvement'), findsOneWidget);
    expect(find.text('Problem'), findsOneWidget);
    expect(find.text('Idea'), findsOneWidget);
    expect(find.descendant(of: find.byType(FeedbackTypeMenu), matching: find.byIcon(Icons.check_rounded)), findsNothing);
    // The field, the rules link and the buttons wait for a topic.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Agree to Rules'), findsNothing);
    expect(submit, findsNothing);
    expect(cancel, findsNothing);
    expect(backend.requests, isEmpty);
  });

  // Settings-1 and -2 in Figma's order, on the refreshed grid; 390 px, dark.
  testWidgets('the menu, pill, field, rules link and buttons use the refreshed look', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openFromSettings(tester, theme: ThemeData.dark());

    final menu = find.byType(FeedbackTypeMenu);
    expect(find.descendant(of: menu, matching: find.byType(CommunityMenuFrame)), findsOneWidget);
    final ideaRow = find.ancestor(of: find.text('Idea'), matching: find.byType(CommunityMenuRow));
    expect(tester.getSize(ideaRow).height, 48);
    expect(find.descendant(of: menu, matching: find.byIcon(Icons.check_rounded)), findsNothing);

    await tapAndSettle(tester, find.text('Improvement'));
    final pill = tester.getRect(find.byType(FeedbackTypePill));
    final field = tester.getRect(find.byType(TextField));
    expect(pill.top, 56 + 16);
    expect(pill.height, 48);
    expect(field.top - pill.bottom, 24);
    expect((field.left, field.width), (16.0, 358.0));
    final pillShape = tester.widget<Material>(find.descendant(of: find.byType(FeedbackTypePill), matching: find.byType(Material)).first).shape!
        as RoundedRectangleBorder;
    expect(pillShape.borderRadius, BorderRadius.circular(12));

    // The open menu ticks the chosen topic; its first row sits on the pill.
    await tapAndSettle(tester, find.text('Improvement'));
    expect(find.descendant(of: menu, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
    expect(tester.getCenter(find.descendant(of: menu, matching: find.text('Choose Topic'))).dy, pill.center.dy);
    await tapAndSettle(tester, find.descendant(of: menu, matching: find.text('Improvement')));

    final link = find.ancestor(of: find.text('Agree to Rules'), matching: find.byType(TextButton));
    expect(tester.getRect(link).top - field.bottom, 8);
    expect(tester.getSize(link).height, 48);
    final linkStyle = tester.widget<TextButton>(link).style!;
    expect(linkStyle.textStyle!.resolve({})!.fontWeight, FontWeight.w600);

    // Cancel (outlined) left, Submit (filled, ✓) right, 48 high, 16 from the sides.
    final cancelBox = tester.getRect(cancel);
    final submitBox = tester.getRect(submit);
    expect(tester.widget<RefreshButton>(cancel).kind, RefreshButtonKind.secondary);
    expect(tester.widget<RefreshButton>(submit).kind, RefreshButtonKind.primary);
    expect((cancelBox.height, submitBox.height), (48, 48));
    expect((cancelBox.left, submitBox.right), (16, 390 - 16));
    expect(submitBox.left - cancelBox.right, 12);
  });

  testWidgets('a topic closes the list and sets the prompt', (tester) async {
    await openFromSettings(tester);

    await tapAndSettle(tester, find.text('Improvement'));
    expect(find.text('Choose Topic'), findsNothing);
    expect(find.text('What do you want to improve?'), findsOneWidget);

    await tapAndSettle(tester, find.text('Improvement')); // the pill opens the list again
    await tapAndSettle(tester, find.text('Idea'));
    expect(find.text("What's your idea?"), findsOneWidget);
  });

  testWidgets('tapping beside the list closes it without a topic', (tester) async {
    await openFromSettings(tester);

    await tester.tapAt(const Offset(20, 500));
    await tester.pumpAndSettle();

    expect(find.text('Improvement'), findsNothing);
    expect(find.text('Choose Topic'), findsOneWidget); // the closed pill
    // Still only the pill.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Agree to Rules'), findsNothing);
    expect(submit, findsNothing);
  });

  testWidgets('a Problem shows its fields, the rules link and the buttons once chosen', (tester) async {
    await openFromSettings(tester);

    await tapAndSettle(tester, find.text('Problem'));
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Agree to Rules'), findsOneWidget);
    expect(submit, findsOneWidget);
    expect(cancel, findsOneWidget);
  });

  testWidgets('✓ works only with a topic and text', (tester) async {
    await openFromSettings(tester);
    expect(submit, findsNothing);

    await tapAndSettle(tester, find.text('Idea'));
    expect(submitEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(submitEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), 'Dark icon');
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('from Settings, a new user agrees, posts, and lands on the list', (tester) async {
    await openFromSettings(tester);
    await fillForm(tester, text: '  Totals per shelf ');
    backend.answer(feedbackJson(26, type: 'improvement'), status: 201);
    backend.answer(pageJson([26, 25])); // the list, loaded after the post
    backend.answer(pageJson([26, 25])); // its revalidation when the list opens

    await tapAndSettle(tester, submit);
    expect(notice, findsOneWidget);
    await tapAndSettle(tester, find.text('Agree'));
    expect(rules, findsOneWidget);
    await tapAndSettle(tester, find.text('Agree'));

    final post = backend.requests.first;
    expect(post.method, 'POST');
    expect(post.headers['X-Anon-Id'], FakeAnonIdSource.createdId);
    expect(jsonDecode(post.body), {'type': 'improvement', 'text': 'Totals per shelf'});
    expect(find.text('Thanks! Posted as #26'), findsOneWidget);
    expect(formScreens, findsNothing);
    expect(listScreens, findsOneWidget);
    expect(find.text('Feedback 26'), findsOneWidget);
  });

  testWidgets('from the list +, a post returns to that list with the post on top', (tester) async {
    await host(tester, agreed: true);
    backend.answer(pageJson([5, 4]));
    unawaited(CommunityPackage.openCommunity(hostContext));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('All Feedback'));

    await tapAndSettle(tester, find.byTooltip('new Feedback'));
    expect(formScreens, findsOneWidget);
    await fillForm(tester, topic: 'Idea', text: 'Dark icon');
    backend.answer(feedbackJson(6), status: 201);
    await tapAndSettle(tester, submit);

    expect(notice, findsNothing);
    expect(rules, findsNothing);
    expect(formScreens, findsNothing);
    expect(listScreens, findsOneWidget);
    expect(find.text('Thanks! Posted as #6'), findsOneWidget);
    final cards = tester.widgetList<Text>(find.textContaining('Feedback ')).map((t) => t.data);
    expect(cards.first, 'Feedback 6');
    expect(backend.requests.map((r) => r.method), ['GET', 'POST']);
  });

  testWidgets('a blocking loading dialog shows while the post is sent', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester);
    final answer = Completer<void>();
    backend.answerLater(answer.future, feedbackJson(26), status: 201);
    backend.answer(pageJson([26]));
    backend.answer(pageJson([26]));

    await tester.tap(submit);
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    answer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(listScreens, findsOneWidget);
  });

  testWidgets('a failed post keeps the form and says why', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester, text: 'Totals');
    backend.fail(status: 429, code: 'rate_limited');

    await tapAndSettle(tester, submit);

    expect(find.text('Too many posts. Try again soon.'), findsOneWidget);
    expect(formScreens, findsOneWidget);
    expect(find.text('Totals'), findsOneWidget);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('the text stops at 100 characters', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester, text: 'a' * 150);

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, hasLength(100));
    expect(find.text('100 / 100'), findsOneWidget);
  });

  testWidgets('a text the backend finds too long says the limit', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester, text: 'Totals');
    backend.fail(status: 400, code: 'bad_request', details: {'field': 'text', 'maxLength': 100});

    await tapAndSettle(tester, submit);

    expect(find.text('Too long. Use at most 100 characters.'), findsOneWidget);
    expect(formScreens, findsOneWidget);
  });

  // The bottom inset of an iPhone with a home indicator, and none.
  for (final inset in [0.0, 34.0]) {
    testWidgets('a failure message floats above ✗ and ✓ (bottom inset $inset)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: inset);
      tester.view.viewPadding = FakeViewPadding(bottom: inset);
      addTearDown(tester.view.reset);
      await openFromSettings(tester, agreed: true);
      await fillForm(tester);
      backend.fail(status: 429, code: 'rate_limited');

      await tapAndSettle(tester, submit);

      final box = tester.getRect(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
      );
      expect(box.bottom, lessThanOrEqualTo(tester.getRect(submit).top));
      expect(box.bottom, lessThanOrEqualTo(tester.getRect(cancel).top));
      // Close above them, not halfway up the screen.
      expect(box.bottom, greaterThan(tester.getRect(submit).top - 20));
    });
  }

  testWidgets('the "Posted" message on the list floats 16 from the sides, radius 12, no extra lift', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester);
    backend.answer(feedbackJson(26), status: 201);
    backend.answer(pageJson([26]));
    backend.answer(pageJson([26]));

    await tapAndSettle(tester, submit);

    expect(listScreens, findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.margin, const EdgeInsets.fromLTRB(16, 0, 16, 12));
    expect(snackBar.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
    final box = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
    final screen = tester.getRect(find.byType(Scaffold).last);
    expect(box.left - screen.left, 16);
    expect(screen.right - box.right, 16);
    expect(tester.widget<Text>(find.text('Thanks! Posted as #26')).style?.fontSize, 15);
  });

  for (final brightness in Brightness.values) {
    testWidgets('messages use the inverse surface, whatever the host snackbar theme ($brightness)', (
      tester,
    ) async {
      final colors = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: brightness);
      // A host snackbar close to its cards, as in Inventory's dark theme.
      final theme = ThemeData(
        colorScheme: colors,
        snackBarTheme: SnackBarThemeData(backgroundColor: colors.surfaceContainerHigh),
      );
      await openFromSettings(tester, agreed: true, theme: theme);
      await fillForm(tester);
      backend.answer(feedbackJson(26), status: 201);
      backend.answer(pageJson([26]));
      backend.answer(pageJson([26]));

      await tapAndSettle(tester, submit);

      expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor, colors.inverseSurface);
      expect(tester.widget<Text>(find.text('Thanks! Posted as #26')).style?.color, colors.onInverseSurface);
    });
  }

  testWidgets('declining the privacy notice sends nothing and unlocks the form', (tester) async {
    await openFromSettings(tester);
    await fillForm(tester);

    await tapAndSettle(tester, submit);
    await tapAndSettle(tester, find.text('Decline'));

    expect(backend.requests, isEmpty);
    expect(formScreens, findsOneWidget);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('"agree to Rules" asks once, then becomes a Rules link', (tester) async {
    await openFromSettings(tester);
    await tapAndSettle(tester, find.text('Idea'));

    await tapAndSettle(tester, find.text('Agree to Rules'));
    expect(rules, findsOneWidget);
    await tapAndSettle(tester, find.text('Agree'));

    expect(find.text('Agree to Rules'), findsNothing);
    await tapAndSettle(tester, find.text('Rules'));
    expect(rules, findsOneWidget);
    expect(find.text('Agree'), findsNothing);
    await tapAndSettle(tester, find.text('Close'));
    expect(rules, findsNothing);
  });

  group('leaving', () {
    testWidgets('✗ with no text closes without asking', (tester) async {
      await openFromSettings(tester);
      await tapAndSettle(tester, find.text('Idea'));

      await tapAndSettle(tester, cancel);

      expect(formScreens, findsNothing);
    });

    testWidgets('✗ with text asks; keep editing stays, discard leaves', (tester) async {
      await openFromSettings(tester);
      await fillForm(tester);

      await tapAndSettle(tester, cancel);
      expect(find.text('Discard this feedback?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Keep editing'));
      expect(formScreens, findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);

      await tapAndSettle(tester, cancel);
      await tapAndSettle(tester, find.text('Discard'));
      expect(formScreens, findsNothing);
    });

    testWidgets('the back arrow with text asks too', (tester) async {
      await openFromSettings(tester);
      await fillForm(tester);

      await tapAndSettle(tester, find.byTooltip('Back'));

      expect(find.text('Discard this feedback?'), findsOneWidget);
    });

    testWidgets('system back with text asks, also as the first screen', (tester) async {
      await openFromSettings(tester);
      await fillForm(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard this feedback?'), findsOneWidget);
      expect(formScreens, findsOneWidget);
    });

    testWidgets('system back without text closes the flow', (tester) async {
      await openFromSettings(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(formScreens, findsNothing);
    });
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow on a small phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await host(tester, theme: theme);
      unawaited(CommunityPackage.openNewFeedback(hostContext));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await fillForm(tester, text: 'A long line of feedback. ' * 30);
      expect(tester.takeException(), isNull);
    });
  }
}
