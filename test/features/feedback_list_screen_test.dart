import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/core/widgets/feedback_card_skeleton.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

void main() {
  late FakeBackend backend;

  Widget app(ThemeData theme) => MaterialApp(
    theme: theme,
    home: FeedbackListScreen(createController: () => FeedbackListController(backend.repository())),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  testWidgets('shows skeletons, then the cards from the backend', (tester) async {
    backend.answer({
      'items': [
        {...feedbackJson(2), 'status': 'in_progress', 'costCents': 5000, 'reactionCount': 5},
        feedbackJson(1),
      ],
      'nextCursor': null,
    });

    await tester.pumpWidget(app(ThemeData.dark()));
    expect(find.byType(FeedbackCardSkeleton), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.byType(FeedbackCardSkeleton), findsNothing);
    expect(find.byType(FeedbackCard), findsNWidgets(2));
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Feedback 2'), findsOneWidget);
    expect(find.text('in progress'), findsOneWidget);
    expect(find.text('💰 50 \$'), findsOneWidget);
    expect(find.text('❤️ 5'), findsOneWidget);
  });

  testWidgets('shows the error with a working retry', (tester) async {
    backend.fail();

    await tester.pumpWidget(app(ThemeData.light()));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong on our side. Please try again later.'), findsOneWidget);

    backend.answer(pageJson([1]));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackCard), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    backend.answer(pageJson([]));

    await tester.pumpWidget(app(ThemeData.dark()));
    await tester.pumpAndSettle();

    expect(find.text('No feedback yet'), findsOneWidget);
  });

  testWidgets('closes its controller when the screen goes away', (tester) async {
    backend.answer(pageJson([1]));
    late FeedbackListController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackListScreen(
          createController: () => controller = FeedbackListController(backend.repository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.isClosed, isFalse);

    await tester.pumpWidget(const SizedBox());

    expect(controller.isClosed, isTrue);
  });

  group('offline bar', () {
    final bar = find.textContaining('Offline. Showing saved feedback.', findRichText: true);

    testWidgets('shows over saved cards when a refresh finds no connection; Try again clears it', (
      tester,
    ) async {
      backend.answer(pageJson([2, 1]));
      await tester.pumpWidget(app(ThemeData.dark()));
      await tester.pumpAndSettle();
      expect(bar, findsNothing);

      backend.offlineAt('GET', '/v1/feedback');
      await tester.fling(find.byType(FeedbackCard).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(bar, findsOneWidget);
      expect(find.byType(FeedbackCard), findsNWidgets(2));

      // Still offline: the bar stays and a snackbar says why.
      backend.offlineAt('GET', '/v1/feedback');
      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
      expect(find.text('No internet connection. Check your connection and try again.'), findsOneWidget);

      backend.answerAt('GET', '/v1/feedback', pageJson([3, 2, 1]));
      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(bar, findsNothing);
      expect(find.byType(FeedbackCard), findsNWidgets(3));
    });

    testWidgets('without saved cards the full message shows instead', (tester) async {
      backend.offlineAt('GET', '/v1/feedback');
      await tester.pumpWidget(app(ThemeData.light()));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection. Check your connection and try again.'), findsOneWidget);
      expect(bar, findsNothing);
    });
  });
}
