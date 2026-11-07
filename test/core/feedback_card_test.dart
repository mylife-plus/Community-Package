import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/feedback_json.dart';

Map<String, dynamic> _problem({String? description = 'Nothing happens'}) => {
  ...feedbackJson(21, type: 'problem'),
  'text': 'Nothing happens\n\n1. Tap plus\n2. Add an item\n3. No item gets added',
  'screenPath': 'Inventory > Sell Item > Add Item',
  'steps': ['Tap plus', 'Add an item', 'No item gets added'],
  'description': description,
  'osVersion': 'iOS 17.4.1',
  'appVersion': '3.2.0',
  'deviceModel': 'iPhone 17 Pro',
};

void main() {
  Future<void> pumpCard(WidgetTester tester, Map<String, dynamic> json, {ThemeData? theme}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Material(child: FeedbackCard(item: FeedbackItem.fromJson(json))),
        ),
      );

  Finder richText(String text) => find.textContaining(text, findRichText: true);

  testWidgets('a Problem shows its path, description, steps and device', (tester) async {
    await pumpCard(tester, _problem());

    expect(find.text('#21'), findsOneWidget);
    expect(richText('Inventory → Sell Item → Add Item'), findsOneWidget);
    expect(find.text('Nothing happens'), findsOneWidget);
    expect(richText('1. Tap plus → 2. Add an item → 3. No item gets added'), findsOneWidget);
    expect(find.text('iOS 17.4.1  App 3.2.0  iPhone 17 Pro'), findsOneWidget);
    // The text repeats the description and steps, so it is not shown.
    expect(richText('\n\n1.'), findsNothing);
  });

  testWidgets('the step numbers take the theme primary colour', (tester) async {
    final theme = ThemeData(colorScheme: const ColorScheme.dark(primary: Color(0xFF0088FF)));
    await pumpCard(tester, _problem(), theme: theme);

    final spans = <TextSpan>[];
    tester.widget<RichText>(richText('1. Tap plus').first).text.visitChildren((span) {
      if (span is TextSpan) spans.add(span);
      return true;
    });

    expect(spans.firstWhere((s) => s.text == '2. ').style?.color, const Color(0xFF0088FF));
    expect(spans.firstWhere((s) => s.text == 'Add an item').style?.color, isNull);
  });

  testWidgets('the optional description reads a step down from the steps', (tester) async {
    await pumpCard(tester, _problem());

    final description = tester.widget<Text>(find.text('Nothing happens')).style!;
    final steps = tester.widget<RichText>(richText('1. Tap plus').first).text.style!;
    final improvement = feedbackJson(5, type: 'improvement');
    await pumpCard(tester, improvement);
    final body = tester.widget<Text>(find.text(improvement['text'] as String)).style!;

    expect(steps, body);
    expect(description.fontSize, lessThan(steps.fontSize!));
    expect(description.fontWeight!.value, lessThan(steps.fontWeight!.value));
    expect(description.color!.a, lessThan(steps.color!.a));
    await pumpCard(tester, _problem());
    expect(
      tester.getTopLeft(richText('1. Tap plus').first).dy - tester.getBottomLeft(find.text('Nothing happens')).dy,
      6,
    );
  });

  testWidgets('a Problem without a description shows path and steps', (tester) async {
    await pumpCard(tester, _problem(description: null));

    expect(richText('Inventory → Sell Item → Add Item'), findsOneWidget);
    expect(richText('1. Tap plus'), findsOneWidget);
    expect(find.text('Nothing happens'), findsNothing);
  });

  testWidgets('a Problem leaves out the device details it does not have', (tester) async {
    await pumpCard(tester, {..._problem(), 'osVersion': null, 'deviceModel': null});

    expect(find.text('App 3.2.0'), findsOneWidget);
  });

  testWidgets('a Problem without steps shows its text', (tester) async {
    await pumpCard(tester, {...feedbackJson(3, type: 'problem'), 'text': 'The app crashes'});

    expect(find.text('The app crashes'), findsOneWidget);
  });

  testWidgets('an Improvement shows only its text', (tester) async {
    await pumpCard(tester, feedbackJson(5, type: 'improvement'));

    expect(find.text('Feedback 5'), findsOneWidget);
    expect(richText('📲'), findsNothing);
  });
}
