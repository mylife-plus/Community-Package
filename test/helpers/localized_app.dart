import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The package's five languages.
const communityLanguages = ['en', 'de', 'es', 'fr', 'pt'];

/// [home] in a MaterialApp with [theme] and [locale], at [size].
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget home, {
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
      supportedLocales: [for (final code in communityLanguages) Locale(code)],
      localizationsDelegates: const [
        CommunityLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

/// The colour a [Text] is drawn in: its own style, or the inherited one.
Color textColor(WidgetTester tester, Finder text) {
  final widget = tester.widget<Text>(text);
  return widget.style?.color ?? DefaultTextStyle.of(tester.element(text)).style.color!;
}
