import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/navigation/community_screens.dart';
import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/feedback_json.dart';

final _tree = [
  ScreenNode(
    'Inventory',
    label: (_) => 'Lager',
    children: [
      ScreenNode('Edit Item', label: (_) => 'Artikel bearbeiten', children: [const ScreenNode('QR Label')]),
    ],
  ),
];

void main() {
  Future<BuildContext> pumpIn(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: const [
          CommunityLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  testWidgets('a saved path shows each known screen by its label', (tester) async {
    final c = await pumpIn(tester);

    expect(screenPathLabels(c, ['Inventory', 'Edit Item', 'QR Label'], _tree), [
      'Lager',
      'Artikel bearbeiten',
      'QR Label', // no label: the name
    ]);
  });

  testWidgets('from the first unknown name on, the path stays as saved', (tester) async {
    final c = await pumpIn(tester);

    expect(screenPathLabels(c, ['Inventory', 'Old Screen', 'QR Label'], _tree), [
      'Lager',
      'Old Screen',
      'QR Label',
    ]);
    expect(screenPathLabels(c, ['Gone'], _tree), ['Gone']);
  });

  testWidgets("the package's own screens use its labels", (tester) async {
    final c = await pumpIn(tester, locale: const Locale('de'));

    expect(screenPathLabels(c, ['Community', 'All Feedback'], const []), ['Community', 'Alles Feedback']);
    expect(screenPathLabels(c, ['Community', 'Community App'], const []), ['Community', 'Community-App']);
  });

  testWidgets('a Problem card shows the path in the app language inside CommunityScreens', (tester) async {
    final item = FeedbackItem.fromJson({
      ...feedbackJson(4, type: 'problem'),
      'screenPath': 'Inventory > Edit Item',
      'steps': ['Open it'],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CommunityScreens(screens: _tree, child: FeedbackCard(item: item)),
        ),
      ),
    );

    expect(find.textContaining('Lager → Artikel bearbeiten', findRichText: true), findsOneWidget);
  });
}
