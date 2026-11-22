import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/community_home/presentation/community_home_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';

void main() {
  late FakeAnonIdSource source;
  late IdentityRepository identity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    source = FakeAnonIdSource();
  });

  // Created inside the test body, so its futures run in the test's fake
  // async zone and pumpAndSettle waits for them.
  Widget app({ThemeData? theme}) {
    identity = IdentityRepository(source);
    addTearDown(identity.dispose);
    return MaterialApp(
      theme: theme,
      home: CommunityHomeScreen(postGate: PostGate(identity: identity)),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  final notice = find.byType(PrivacyNoticeSheet);

  testWidgets('shows the intro, all Feedback and the Privacy Notice link only', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Community App'), findsOneWidget);
    expect(find.textContaining('100% open source'), findsOneWidget);
    expect(find.text('All Feedback'), findsOneWidget);
    expect(find.text('Privacy Notice'), findsOneWidget);
    // These screens come in later slices.
    expect(find.text('Follow the Progress'), findsNothing);
    expect(find.text('Costs & Tips'), findsNothing);
    expect(find.text('Give a Tip'), findsNothing);
  });

  testWidgets('Privacy Notice asks a new user; decline creates nothing', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Privacy Notice');
    expect(notice, findsOneWidget);
    expect(find.text('Agree'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tapText(tester, 'Decline');

    expect(notice, findsNothing);
    expect(source.creates, 0);
    expect(await identity.requestAnonId(), isNull);
  });

  testWidgets('agree from the link creates the ID; reopening shows it with close', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Privacy Notice');
    await tapText(tester, 'Agree');
    expect(await identity.requestAnonId(), FakeAnonIdSource.createdId);

    await tapText(tester, 'Privacy Notice');

    expect(find.text('Your ID: ${FakeAnonIdSource.createdId}'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Agree'), findsNothing);
    expect(find.text('Decline'), findsNothing);

    await tapText(tester, 'Close');
    expect(notice, findsNothing);
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(theme: theme));

      expect(tester.takeException(), isNull);
    });
  }
}
