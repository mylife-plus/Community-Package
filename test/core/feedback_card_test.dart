import 'package:community_package/src/core/theme/community_theme.dart';
import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/core/widgets/inner_shadow.dart';
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

  testWidgets('the counts stay on the right with a status and a cost', (tester) async {
    Future<double> heartRight(Map<String, dynamic> json) async {
      await pumpCard(tester, json);
      return tester.getTopRight(find.textContaining('❤️', findRichText: true)).dx;
    }

    final plain = await heartRight(feedbackJson(9, reactionCount: 14, commentCount: 3));
    final full = await heartRight({
      ...feedbackJson(9, status: 'planned', reactionCount: 14, commentCount: 3),
      'costCents': 9000,
    });

    expect(full, plain);
  });

  testWidgets('a long cost ellipsizes instead of pushing the counts', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(tester, {
      ...feedbackJson(9, status: 'in_progress', reactionCount: 140, commentCount: 30),
      'costCents': 123456789,
    });

    expect(tester.takeException(), isNull);
  });

  group('Figma layout (Settings-15, Settings-8)', () {
    Future<Offset> pumpAt390(WidgetTester tester, Map<String, dynamic> json) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          // Figma's dark colours: black cards on the dark blue screen.
          theme: communityTheme(
            ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000), onSurface: Color(0xFFFFFFFF))),
          ),
          home: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FeedbackCard(item: FeedbackItem.fromJson(json)),
                ),
              ],
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byType(FeedbackCard));
    }

    testWidgets('a two-line card is 121 high with Figma positions', (tester) async {
      final card = await pumpAt390(tester, {
        ...feedbackJson(2, status: 'in_progress', reactionCount: 5),
        'text': 'First line\nsecond line',
      });

      expect(tester.getSize(find.byType(FeedbackCard)).height, 121);
      expect(tester.getTopLeft(find.text('💡')) - card, const Offset(5, 6));
      expect(tester.getTopLeft(find.text('#2')).dy - card.dy, 10);
      expect(tester.getTopLeft(find.text('First line\nsecond line')) - card, const Offset(12, 41));
      // The test font is wider than real ones, so only the chip's right edge.
      final chip = tester.getRect(find.byType(InnerShadow)).shift(-card);
      expect((chip.top, chip.bottom, chip.right), (90.0, 116.0, 370.0));
      expect(tester.getTopLeft(find.text('in progress')).dx - card.dx, moreOrLessEquals(34, epsilon: 0.5));
    });

    testWidgets('the heart chip has a red border outside it only when hearted', (tester) async {
      BoxDecoration chip() => tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;

      await pumpAt390(tester, feedbackJson(2, reactionCount: 5));
      expect((chip().border! as Border).top.color.a, 0);

      await pumpAt390(tester, {...feedbackJson(2, reactionCount: 5), 'reacted': true});
      await tester.pumpAndSettle();
      final side = (chip().border! as Border).top;
      expect(side.color, const Color(0xFFFF0000));
      expect(side.strokeAlign, BorderSide.strokeAlignOutside);
    });

    testWidgets('Problem lines: steps 11.5 under the path, device 9 under the steps', (tester) async {
      await pumpAt390(tester, _problem(description: null));

      final path = tester.getRect(richText('Inventory →').first);
      final steps = tester.getRect(richText('1. Tap plus').first);
      final device = find.text('iOS 17.4.1  App 3.2.0  iPhone 17 Pro');
      expect(steps.top - path.bottom, 11.5);
      expect(tester.getTopLeft(device).dy - steps.bottom, 9);
      final style = tester.widget<Text>(device).style!;
      expect((style.fontSize, style.fontWeight, style.color?.toARGB32()), (16.0, FontWeight.w500, 0xFFBABABA));
    });
  });
}
