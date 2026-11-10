import 'package:community_package/src/core/widgets/community_text_field.dart';
import 'package:community_package/src/features/feedback_detail/presentation/feedback_detail_controller.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, int maxLength) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CommunityTextField(
          controller: controller,
          hint: 'hint',
          maxLength: maxLength,
        ),
      ),
    ),
  );

  test('texts and comments allow 100 characters, steps 500', () {
    expect(NewFeedbackController.maxTextLength, 100);
    expect(FeedbackDetailController.maxCommentLength, 100);
    expect(NewFeedbackController.maxStepLength, 500);
  });

  testWidgets('stops input at the limit, counting an emoji as one', (
    tester,
  ) async {
    await pump(tester, 100);

    await tester.enterText(find.byType(TextField), 'a' * 120);
    expect(controller.text, hasLength(100));

    await tester.enterText(find.byType(TextField), '👍🏽' * 120);
    expect(controller.text.characters, hasLength(100));
  });

  for (final (max, from) in [(100, 80), (500, 400)]) {
    testWidgets('shows the count only from $from of $max', (tester) async {
      await pump(tester, max);

      await tester.enterText(find.byType(TextField), 'a' * (from - 1));
      await tester.pump();
      expect(find.textContaining(' / $max'), findsNothing);

      await tester.enterText(find.byType(TextField), 'a' * from);
      await tester.pump();
      expect(find.text('$from / $max'), findsOneWidget);
    });
  }
}
