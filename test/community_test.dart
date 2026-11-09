import 'dart:async';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/features/community_home/presentation/community_home_screen.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_anon_id_source.dart';
import 'helpers/fake_backend.dart';
import 'helpers/feedback_json.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(CommunityPackage.reset);

  test('config throws before init', () {
    expect(() => CommunityPackage.config, throwsStateError);
  });

  test('init stores the config', () async {
    await CommunityPackage.init(
      const CommunityConfig(
        backendUrl: 'https://community.example.workers.dev',
        appId: 'inventory',
        privacyPolicyUrl: 'https://example.com/privacy',
      ),
    );

    expect(CommunityPackage.config.appId, 'inventory');
    expect(
      CommunityPackage.config.backendUrl,
      'https://community.example.workers.dev',
    );
    expect(CommunityDependencies.config.privacyPolicyUrl, 'https://example.com/privacy');
  });

  test('init can run again, for example after a hot restart', () async {
    const config = CommunityConfig(backendUrl: 'https://example.com', appId: 'inventory');

    await CommunityPackage.init(config);
    await CommunityPackage.init(config);

    expect(CommunityPackage.config.appId, 'inventory');
  });

  testWidgets('openCommunity before init fails with a clear error', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(() => CommunityPackage.openCommunity(context), throwsStateError);
  });

  testWidgets('without the delegate the labels fall back to English', (tester) async {
    late CommunityLocalizations labels;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            labels = CommunityLocalizations.of(c);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(labels.feedbackTitle, 'Feedback');
  });

  group('openCommunity', () {
    const config = CommunityConfig(backendUrl: 'https://example.com', appId: 'inventory');
    late BuildContext context;
    late FakeBackend backend;

    Future<void> open(WidgetTester tester) async {
      backend = FakeBackend();
      await CommunityPackage.init(config);
      CommunityDependencies.register(
        config,
        httpClient: backend.client,
        anonIdSource: FakeAnonIdSource(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(CommunityPackage.openCommunity(context));
      await tester.pumpAndSettle();
    }

    Future<void> openList(WidgetTester tester) async {
      await open(tester);
      backend.answer(pageJson([1]));
      await tester.tap(find.text('all Feedback'));
      await tester.pumpAndSettle();
    }

    // skipOffstage: false also counts a screen hidden under another one.
    final homeScreens = find.byType(CommunityHomeScreen, skipOffstage: false);
    final listScreens = find.byType(FeedbackListScreen, skipOffstage: false);

    testWidgets('opens exactly one Community App screen', (tester) async {
      await open(tester);

      expect(homeScreens, findsOneWidget);
      expect(listScreens, findsNothing);
      expect(backend.requests, isEmpty);
    });

    testWidgets('all Feedback opens the list on top', (tester) async {
      await openList(tester);

      expect(listScreens, findsOneWidget);
      expect(homeScreens, findsOneWidget);
      expect(find.text('Feedback 1'), findsOneWidget);
    });

    testWidgets('the back arrow on the list returns to the Community App screen', (tester) async {
      await openList(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(listScreens, findsNothing);
      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('system back on the list returns to the Community App screen', (tester) async {
      await openList(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(listScreens, findsNothing);
      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('the back arrow on the Community App screen closes the flow', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(homeScreens, findsNothing);
    });

    testWidgets('system back on the Community App screen closes the flow', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(homeScreens, findsNothing);
    });
  });

  test('the delegate accepts every locale and serves English labels for now', () async {
    const delegate = CommunityLocalizations.delegate;
    for (final code in ['en', 'de', 'es', 'fr', 'pt', 'ja']) {
      expect(delegate.isSupported(Locale(code)), isTrue, reason: code);
    }
    expect((await delegate.load(const Locale('de'))).feedbackTitle, 'Feedback');
  });
}
