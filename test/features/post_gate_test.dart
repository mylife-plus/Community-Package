import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';

void main() {
  late FakeAnonIdSource source;
  late IdentityRepository identity;
  late int posts;
  late int hearts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    source = FakeAnonIdSource();
    posts = 0;
    hearts = 0;
  });

  /// A screen with a Post and a Heart button, each behind the gate, like
  /// New Feedback, comments and the heart chip will use it.
  ///
  /// The repository is created here, inside the test body: created in
  /// setUp, its SharedPreferences future would complete outside the test's
  /// fake async zone and pumpAndSettle would not wait for it.
  Widget app({String? privacyPolicyUrl, ThemeData? theme}) {
    identity = IdentityRepository(source);
    addTearDown(identity.dispose);
    final gate = PostGate(identity: identity, privacyPolicyUrl: privacyPolicyUrl);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () async {
                  if (await gate.ensureCanPost(context)) posts++;
                },
                child: const Text('Post'),
              ),
              TextButton(
                onPressed: () async {
                  if (await gate.ensureIdentity(context)) hearts++;
                },
                child: const Text('Heart'),
              ),
              TextButton(onPressed: () => gate.openRules(context), child: const Text('Rules')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  final notice = find.byType(PrivacyNoticeSheet);
  final rules = find.byType(RulesSheet);

  testWidgets('decline keeps the user read-only: no ID and the post does not run', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');
    expect(notice, findsOneWidget);
    await tapText(tester, 'decline');

    expect(notice, findsNothing);
    expect(rules, findsNothing);
    expect(posts, 0);
    expect(source.creates, 0);
    expect(await identity.requestAnonId(), isNull);
  });

  testWidgets('declined users are asked again on the next try', (tester) async {
    await tester.pumpWidget(app());
    await tapText(tester, 'Post');
    await tapText(tester, 'decline');

    await tapText(tester, 'Post');

    expect(notice, findsOneWidget);
  });

  testWidgets('agree creates the ID, then the rules, then the post continues', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');
    await tapText(tester, 'agree');
    expect(await identity.requestAnonId(), FakeAnonIdSource.createdId);
    expect(rules, findsOneWidget);
    expect(find.text('Do Not'), findsOneWidget);
    expect(find.text('Share private information'), findsOneWidget);
    expect(find.text('Submit unrelated content'), findsOneWidget);
    expect(find.text('Use harassment or hate speech'), findsOneWidget);
    expect(posts, 0);

    await tapText(tester, 'agree');

    expect(rules, findsNothing);
    expect(posts, 1);
    expect((await identity.load()).rulesAgreed, isTrue);
  });

  testWidgets('once agreed to both, posting asks nothing', (tester) async {
    await tester.pumpWidget(app());
    await tapText(tester, 'Post');
    await tapText(tester, 'agree');
    await tapText(tester, 'agree');

    await tapText(tester, 'Post');

    expect(notice, findsNothing);
    expect(rules, findsNothing);
    expect(posts, 2);
    expect(source.creates, 1);
  });

  testWidgets('closing the rules without agreeing stops the post', (tester) async {
    await tester.pumpWidget(app());
    await tapText(tester, 'Post');
    await tapText(tester, 'agree');
    expect(rules, findsOneWidget);

    // Tap the dimmed area above the sheet.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(rules, findsNothing);
    expect(posts, 0);
    expect((await identity.load()).rulesAgreed, isFalse);

    await tapText(tester, 'Post');
    expect(notice, findsNothing);
    expect(rules, findsOneWidget);
  });

  testWidgets('a user with an ID who never agreed to the rules only sees the rules', (tester) async {
    source.id = FakeAnonIdSource.createdId;
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');

    expect(notice, findsNothing);
    expect(rules, findsOneWidget);
  });

  testWidgets('the rules link asks first, without the privacy notice', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Rules');
    expect(notice, findsNothing);
    expect(rules, findsOneWidget);
    await tapText(tester, 'agree');

    expect(rules, findsNothing);
    expect((await identity.load()).rulesAgreed, isTrue);
    expect(source.creates, 0);
  });

  testWidgets('once agreed, the rules link shows the rules with close only', (tester) async {
    SharedPreferences.setMockInitialValues({IdentityRepository.rulesAgreedKey: true});
    await tester.pumpWidget(app());

    await tapText(tester, 'Rules');
    expect(rules, findsOneWidget);
    expect(find.text('agree'), findsNothing);
    await tapText(tester, 'close');

    expect(rules, findsNothing);
  });

  testWidgets('a heart only needs the privacy notice, never the rules', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Heart');
    await tapText(tester, 'agree');

    expect(rules, findsNothing);
    expect(hearts, 1);
    expect(await identity.requestAnonId(), FakeAnonIdSource.createdId);

    await tapText(tester, 'Heart');
    expect(notice, findsNothing);
    expect(hearts, 2);
  });

  testWidgets('declining before a heart keeps it from running', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Heart');
    await tapText(tester, 'decline');

    expect(hearts, 0);
    expect(source.creates, 0);
  });

  testWidgets('a failed save shows an error and stops the action', (tester) async {
    source.failCreates = true;
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');
    await tapText(tester, 'agree');

    expect(find.text('Could not save on this device. Please try again.'), findsOneWidget);
    expect(rules, findsNothing);
    expect(posts, 0);
  });

  testWidgets('without a Privacy Policy URL the link sentence is left out', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');

    expect(find.textContaining('Bundesdatenschutzbeauftragte', findRichText: true), findsOneWidget);
    expect(find.textContaining('Read our full', findRichText: true), findsNothing);
    expect(find.textContaining('Privacy Policy', findRichText: true), findsNothing);
  });

  testWidgets('with a Privacy Policy URL the sentence and link are shown', (tester) async {
    await tester.pumpWidget(app(privacyPolicyUrl: 'https://example.com/privacy'));

    await tapText(tester, 'Post');

    expect(find.textContaining('Read our full', findRichText: true), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  double moreBelowOpacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byKey(PrivacyNoticeSheet.moreBelowKey)).opacity;

  testWidgets('cut-off notice text shows a scrollbar and a line until the end', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');

    final scrollbar = tester.widget<Scrollbar>(
      find.descendant(of: notice, matching: find.byType(Scrollbar)),
    );
    expect(scrollbar.thumbVisibility, isTrue);
    expect(moreBelowOpacity(tester), 1);

    await tester.drag(
      find.descendant(of: notice, matching: find.byType(SingleChildScrollView)),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    expect(moreBelowOpacity(tester), 0);
  });

  testWidgets('no line when the whole notice fits', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    await tapText(tester, 'Post');

    expect(moreBelowOpacity(tester), 0);
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('both sheets lay out without overflow in $name mode', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(theme: theme, privacyPolicyUrl: 'https://example.com/p'));

      await tapText(tester, 'Post');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'agree');

      expect(tester.takeException(), isNull);
      expect(rules, findsOneWidget);
    });
  }
}
