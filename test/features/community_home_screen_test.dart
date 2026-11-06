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
    expect(find.text('all Feedback'), findsOneWidget);
    expect(find.text('Privacy Notice'), findsOneWidget);
    // These screens come in later slices.
    expect(find.text('follow the Progress'), findsNothing);
    expect(find.text('Costs & Tips'), findsNothing);
    expect(find.text('give a Tip'), findsNothing);
  });

  testWidgets('Privacy Notice asks a new user; decline creates nothing', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Privacy Notice');
    expect(notice, findsOneWidget);
    expect(find.text('agree'), findsOneWidget);
    expect(find.text('decline'), findsOneWidget);

    await tapText(tester, 'decline');

    expect(notice, findsNothing);
    expect(source.creates, 0);
    expect(await identity.requestAnonId(), isNull);
  });

  testWidgets('agree from the link creates the ID; reopening shows it with close', (tester) async {
    await tester.pumpWidget(app());

    await tapText(tester, 'Privacy Notice');
    await tapText(tester, 'agree');
    expect(await identity.requestAnonId(), FakeAnonIdSource.createdId);

    await tapText(tester, 'Privacy Notice');

    expect(find.text('Your ID: ${FakeAnonIdSource.createdId}'), findsOneWidget);
    expect(find.text('close'), findsOneWidget);
    expect(find.text('agree'), findsNothing);
    expect(find.text('decline'), findsNothing);

    await tapText(tester, 'close');
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
