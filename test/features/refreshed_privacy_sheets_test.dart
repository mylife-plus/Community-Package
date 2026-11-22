import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/community_popups.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/host_themes.dart';

const _languages = ['en', 'de', 'es', 'fr', 'pt'];

Future<BuildContext> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  String locale = 'en',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: Locale(locale),
      supportedLocales: [for (final code in _languages) Locale(code)],
      localizationsDelegates: const [
        CommunityLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return context;
}

Future<void> _open(WidgetTester tester, BuildContext context, Widget sheet) async {
  showCommunitySheet<Object?>(context, refreshed: true, builder: (_) => sheet);
  await tester.pumpAndSettle();
}

/// The rule cards: the Containers that hold a rule's text.
Finder _ruleCard(String text) => find.ancestor(of: find.text(text), matching: find.byType(Container)).first;

void main() {
  testWidgets('the privacy notice is a refreshed sheet, full height, Close full width', (tester) async {
    final context = await _pump(tester);
    await _open(tester, context, const PrivacyNoticeSheet(anonId: 'abc'));

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, RefreshColors.sheet(context));
    expect(sheet.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))));
    final close = tester.getRect(find.widgetWithText(RefreshButton, 'Close'));
    expect(close.height, 48);
    expect(close.left, 24);
    expect(390 - close.right, 24);
    expect(tester.widget<RefreshButton>(find.widgetWithText(RefreshButton, 'Close')).kind, RefreshButtonKind.secondary);
  });

  testWidgets('rules: Agree filled and full width; Close outlined once agreed', (tester) async {
    final context = await _pump(tester);
    await _open(tester, context, const RulesSheet());
    final agree = find.widgetWithText(RefreshButton, 'Agree');
    expect(tester.widget<RefreshButton>(agree).kind, RefreshButtonKind.primary);
    expect(tester.getRect(agree).width, 390 - 48);
    expect(tester.getRect(agree).height, 48);
    closePopup(tester.element(agree));
    await tester.pumpAndSettle();

    await _open(tester, context, const RulesSheet(agreed: true));
    final close = find.widgetWithText(RefreshButton, 'Close');
    expect(tester.widget<RefreshButton>(close).kind, RefreshButtonKind.secondary);
    expect(tester.getRect(close).width, 390 - 48);
  });

  testWidgets('rules: tinted red cards with a red edge, radius 12, 8 apart', (tester) async {
    final context = await _pump(tester);
    await _open(tester, context, const RulesSheet());
    final l = CommunityLocalizations.of(context);

    final first = _ruleCard(l.ruleNoPrivateInfo);
    final decoration = tester.widget<Container>(first).decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(decoration.border!.top.width, 1.5);
    expect(tester.getRect(_ruleCard(l.ruleNoUnrelated)).top - tester.getRect(first).bottom, 8);
  });

  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    for (final code in _languages) {
      testWidgets('$name, $code at 320 px: both sheets fit; text 4.5:1, the red edge 3:1', (tester) async {
        final context = await _pump(tester, theme: theme, locale: code, size: const Size(320, 568));
        final l = CommunityLocalizations.of(context);

        await _open(tester, context, const PrivacyNoticeSheet());
        expect(tester.takeException(), isNull);
        for (final label in [l.decline, l.agree]) {
          final text = find.text(sentenceCase(label));
          expect(text, findsOneWidget);
          expect(tester.getRect(text).bottom, lessThanOrEqualTo(568));
        }
        closePopup(tester.element(find.byType(PrivacyNoticeSheet)));
        await tester.pumpAndSettle();

        await _open(tester, context, const RulesSheet());
        expect(tester.takeException(), isNull);
        final sheetContext = tester.element(find.byType(RulesSheet));
        final sheet = RefreshColors.sheet(sheetContext);
        for (final rule in [l.ruleNoPrivateInfo, l.ruleNoUnrelated, l.ruleNoHate]) {
          final decoration = tester.widget<Container>(_ruleCard(rule)).decoration! as BoxDecoration;
          final text = tester.widget<Text>(find.text(rule));
          expect(RefreshColors.contrast(text.style!.color!, decoration.color!), greaterThanOrEqualTo(4.5));
          expect(RefreshColors.contrast(decoration.border!.top.color, sheet), greaterThanOrEqualTo(3));
        }
      });
    }
  }
}
