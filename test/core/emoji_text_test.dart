import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/feedback_json.dart';

void main() {
  // Inter has its own ❤ and ⚠, so emoji must not inherit the host font.
  Future<void> pumpCard(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Inter'),
      home: Material(
        child: FeedbackCard(
          item: FeedbackItem.fromJson({
            ...feedbackJson(1, type: 'problem'),
            'reactionCount': 5,
            'costCents': 5000,
          }),
        ),
      ),
    ),
  );

  TextSpan spanOf(WidgetTester tester, String text) {
    final rich = tester.widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    return rich.text as TextSpan;
  }

  String? familyOfChild(TextSpan root, String text) {
    String? family;
    root.visitChildren((span) {
      if (span is TextSpan && span.text == text) family = span.style?.fontFamily;
      return family == null;
    });
    return family;
  }

  testWidgets('the type emoji uses the color emoji font', (tester) async {
    await pumpCard(tester);

    expect(spanOf(tester, '⚠️').style?.fontFamily, 'Apple Color Emoji');
  });

  testWidgets('hearts and cost use the emoji font only for the emoji', (tester) async {
    await pumpCard(tester);

    for (final (text, emoji) in [('❤️ 5', '❤️'), ('💰 50 \$', '💰')]) {
      final root = spanOf(tester, text);
      expect(root.style?.fontFamily, 'Inter', reason: text);
      expect(familyOfChild(root, emoji), 'Apple Color Emoji', reason: text);
    }
  });
}
