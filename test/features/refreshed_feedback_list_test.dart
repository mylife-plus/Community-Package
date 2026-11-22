import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/core/widgets/feedback_card_skeleton.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';
import '../helpers/host_themes.dart';
import '../helpers/localized_app.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  Widget screen() => FeedbackListScreen(createController: () => FeedbackListController(backend.repository()));

  Map<String, dynamic> page({String? nextCursor}) => {
    'items': [
      {...feedbackJson(12, status: 'in_progress', costCents: 70000, reactionCount: 1234, commentCount: 987)},
      feedbackJson(11, type: 'problem'),
      feedbackJson(10, type: 'improvement', status: 'done'),
    ],
    'nextCursor': nextCursor,
  };

  testWidgets('All Feedback cards use the refreshed look: cost right after the status', (tester) async {
    backend.answer(page());
    await pumpLocalized(tester, screen());
    await tester.pumpAndSettle();

    expect(find.byType(CommunityRefresh), findsOneWidget);
    final card = find.byType(FeedbackCard).first;
    final status = tester.getRect(find.descendant(of: card, matching: find.text('in progress')));
    final cost = tester.getRect(find.descendant(of: card, matching: find.textContaining('💰')));
    final comments = tester.getRect(find.descendant(of: card, matching: find.textContaining('987')));
    expect(cost.left, greaterThan(status.right));
    expect(cost.left - status.right, lessThan(20));
    expect(comments.left, greaterThan(cost.right));
  });

  testWidgets('loading cards have the refreshed card shape', (tester) async {
    backend.answer(page());
    await pumpLocalized(tester, screen());

    final skeleton = find.byType(FeedbackCardSkeleton).first;
    final box = tester.widget<DecoratedBox>(find.descendant(of: skeleton, matching: find.byType(DecoratedBox)).first);
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(decoration.color, RefreshColors.card(tester.element(skeleton)));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed next page shows an outlined Retry 48 high', (tester) async {
    backend.answer(page(nextCursor: 'next'));
    backend.fail();
    await pumpLocalized(tester, screen(), size: const Size(390, 500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    final retry = find.byType(RefreshButton);
    expect(retry, findsOneWidget);
    expect(tester.widget<RefreshButton>(retry).kind, RefreshButtonKind.secondary);
    expect(tester.getSize(retry).height, 48);
  });

  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    for (final code in communityLanguages) {
      testWidgets('$name, $code at 320 px: loading and cards fit; text reads at 4.5:1', (tester) async {
        backend.answer(page());
        await pumpLocalized(tester, screen(), theme: theme, locale: code, size: const Size(320, 568));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cardFinder = find.byType(FeedbackCard).first;
        final card = RefreshColors.card(tester.element(cardFinder));
        expect(card, isNot(theme.scaffoldBackgroundColor));
        expect(
          RefreshColors.contrast(textColor(tester, find.descendant(of: cardFinder, matching: find.text('Feedback 12'))), card),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          RefreshColors.contrast(textColor(tester, find.descendant(of: cardFinder, matching: find.text('#12'))), card),
          greaterThanOrEqualTo(4.5),
        );
        final l = CommunityLocalizations.forLocale(Locale(code));
        expect(find.text(l.feedbackTitle), findsOneWidget);
      });
    }
  }
}
