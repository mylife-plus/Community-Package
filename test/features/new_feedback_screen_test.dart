import 'dart:async';
import 'dart:convert';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_screen.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
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
  final submit = find.byTooltip('submit');
  final cancel = find.byTooltip('cancel');
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
  Future<void> openFromSettings(WidgetTester tester, {bool agreed = false}) async {
    await host(tester, agreed: agreed);
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

  testWidgets('opens one New Feedback screen with the topic list open', (tester) async {
    await openFromSettings(tester);

    expect(formScreens, findsOneWidget);
    expect(listScreens, findsNothing);
    expect(find.text('new Feedback'), findsOneWidget);
    // The closed pill stays laid out under the list, hidden and untappable.
    expect(find.text('Choose Topic').hitTestable(), findsOneWidget);
    expect(find.text('Improvement'), findsOneWidget);
    expect(find.text('Idea'), findsOneWidget);
    expect(find.text('Problem'), findsNothing); // arrives with the problem form
    expect(find.text('Your improvement idea...'), findsOneWidget);
    expect(find.text('agree to Rules'), findsOneWidget);
    expect(backend.requests, isEmpty);
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
  });

  testWidgets('✓ works only with a topic and text', (tester) async {
    await openFromSettings(tester);
    expect(submitEnabled(tester), isFalse);

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
    await tapAndSettle(tester, find.text('agree'));
    expect(rules, findsOneWidget);
    await tapAndSettle(tester, find.text('agree'));

    final post = backend.requests.first;
    expect(post.method, 'POST');
    expect(post.headers['X-Anon-Id'], FakeAnonIdSource.createdId);
    expect(jsonDecode(post.body), {'type': 'improvement', 'text': 'Totals per shelf'});
    expect(find.text('Thanks! Posted as #26'), findsOneWidget);
    expect(formScreens, findsNothing);
    expect(listScreens, findsOneWidget);
    expect(find.text('Feedback 26'), findsOneWidget);
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

  testWidgets('the "Posted" message on the list keeps the normal place', (tester) async {
    await openFromSettings(tester, agreed: true);
    await fillForm(tester);
    backend.answer(feedbackJson(26), status: 201);
    backend.answer(pageJson([26]));
    backend.answer(pageJson([26]));

    await tapAndSettle(tester, submit);

    expect(listScreens, findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).margin, isNull);
  });

  testWidgets('declining the privacy notice sends nothing and unlocks the form', (tester) async {
    await openFromSettings(tester);
    await fillForm(tester);

    await tapAndSettle(tester, submit);
    await tapAndSettle(tester, find.text('decline'));

    expect(backend.requests, isEmpty);
    expect(formScreens, findsOneWidget);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('"agree to Rules" asks once, then becomes a Rules link', (tester) async {
    await openFromSettings(tester);
    await tapAndSettle(tester, find.text('Idea'));

    await tapAndSettle(tester, find.text('agree to Rules'));
    expect(rules, findsOneWidget);
    await tapAndSettle(tester, find.text('agree'));

    expect(find.text('agree to Rules'), findsNothing);
    await tapAndSettle(tester, find.text('Rules'));
    expect(rules, findsOneWidget);
    expect(find.text('agree'), findsNothing);
    await tapAndSettle(tester, find.text('close'));
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
      await tapAndSettle(tester, find.text('keep editing'));
      expect(formScreens, findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);

      await tapAndSettle(tester, cancel);
      await tapAndSettle(tester, find.text('discard'));
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
