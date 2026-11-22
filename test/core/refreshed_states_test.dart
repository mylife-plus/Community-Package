import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/community_message.dart';
import 'package:community_package/src/core/widgets/community_offline_banner.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/host_themes.dart';

const _languages = ['en', 'de', 'es', 'fr', 'pt'];

/// Pumps [body] under an app bar with [theme] and [locale] at [size].
Future<void> _pump(
  WidgetTester tester, {
  required Widget Function(CommunityLocalizations l) body,
  ThemeData? theme,
  String locale = 'en',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
      home: Scaffold(appBar: AppBar(), body: Builder(builder: (context) => body(CommunityLocalizations.of(context)))),
    ),
  );
}

Widget _states(CommunityLocalizations l) => Column(
  children: [
    CommunityOfflineBanner(visible: true, message: l.offlineShowingSaved, actionLabel: l.retry, onAction: () {}),
    Expanded(
      child: CommunityMessage(
        emoji: '📡',
        title: l.emptyFeedbackTitle,
        body: l.emptyFeedbackBody,
        actionLabel: l.retry,
        onAction: () {},
      ),
    ),
  ],
);

void main() {
  testWidgets('message: title 17, body 15, an outlined Retry 48 high', (tester) async {
    await _pump(tester, body: _states);

    final message = find.byType(CommunityMessage);
    final retry = find.descendant(of: message, matching: find.byType(RefreshButton));
    expect(tester.widget<RefreshButton>(retry).kind, RefreshButtonKind.secondary);
    expect(tester.getSize(retry).height, 48);
    final l = CommunityLocalizations.forLocale(const Locale('en'));
    expect(tester.widget<Text>(find.text(l.emptyFeedbackTitle)).style?.fontSize, 17);
    expect(tester.widget<Text>(find.text(l.emptyFeedbackBody)).style?.fontSize, 15);
  });

  testWidgets('offline bar: at least 48 high, Try again 48 high', (tester) async {
    await _pump(tester, body: _states);

    final banner = find.byType(CommunityOfflineBanner);
    expect(tester.getSize(banner).height, greaterThanOrEqualTo(48));
    final retry = find.descendant(of: banner, matching: find.byType(TextButton));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(find.descendant(of: banner, matching: find.text('Try again')), findsOneWidget);
  });

  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    for (final code in _languages) {
      testWidgets('$name, $code at 320 px: states fit; the bar stands out; text reads at 4.5:1', (tester) async {
        await _pump(tester, body: _states, theme: theme, locale: code, size: const Size(320, 568));
        expect(tester.takeException(), isNull);

        final bannerFinder = find.byType(CommunityOfflineBanner);
        final bar = tester.widget<Container>(find.descendant(of: bannerFinder, matching: find.byType(Container)).first);
        final barColor = bar.color!;
        // Visible on every host, also where surfaceContainerHighest is the
        // screen colour.
        expect(barColor, isNot(theme.scaffoldBackgroundColor));
        final l = CommunityLocalizations.forLocale(Locale(code));
        final barText = tester.widget<RichText>(
          find.descendant(
            of: bannerFinder,
            matching: find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().contains(l.offlineShowingSaved),
            ),
          ),
        );
        expect(RefreshColors.contrast(barText.text.style!.color!, barColor), greaterThanOrEqualTo(4.5));
        final retry = find.descendant(of: bannerFinder, matching: find.text(sentenceCase(l.retry)));
        final retryColor = DefaultTextStyle.of(tester.element(retry)).style.color!;
        expect(RefreshColors.contrast(retryColor, barColor), greaterThanOrEqualTo(4.5));

        final body = tester.widget<Text>(find.text(l.emptyFeedbackBody));
        expect(RefreshColors.contrast(body.style!.color!, theme.scaffoldBackgroundColor), greaterThanOrEqualTo(4.5));
      });
    }
  }
}
