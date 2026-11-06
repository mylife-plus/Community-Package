import 'dart:async';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        backendUrl: 'https://community-dev.qureshicreatives.workers.dev',
        appId: 'inventory',
      ),
    );

    expect(CommunityPackage.config.appId, 'inventory');
    expect(
      CommunityPackage.config.backendUrl,
      'https://community-dev.qureshicreatives.workers.dev',
    );
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

    Future<void> open(WidgetTester tester) async {
      final backend = FakeBackend()..answer(pageJson([1]));
      await CommunityPackage.init(config);
      CommunityDependencies.register(config, httpClient: backend.client);
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

    // skipOffstage: false also counts a screen hidden under another one.
    final listScreens = find.byType(FeedbackListScreen, skipOffstage: false);

    testWidgets('pushes exactly one feedback list', (tester) async {
      await open(tester);

      expect(listScreens, findsOneWidget);
    });

    testWidgets('the back arrow closes the flow', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(listScreens, findsNothing);
    });

    testWidgets('system back closes the flow', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(listScreens, findsNothing);
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
