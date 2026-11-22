import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host themes like the three apps': a hand-built scheme (Inventory), the
/// Flutter defaults (SpaceTime) and a seeded scheme (money).
final _themes = <String, ThemeData>{
  'hand-built dark': ThemeData(
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF2C9DFF),
      onPrimary: Colors.white,
      secondary: Color(0xFF4BE000),
      onSecondary: Colors.black,
      surface: Color(0xFF141C2B),
      onSurface: Color(0xFFE8EDF5),
      error: Color(0xFFFF5A5A),
      onError: Colors.white,
    ),
  ),
  'hand-built light': ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF2F4F8),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0066CC),
      onPrimary: Colors.white,
      secondary: Color(0xFF2E8B00),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF111827),
      error: Color(0xFFD00000),
      onError: Colors.white,
    ),
  ),
  'default light': ThemeData.light(),
  'default dark': ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
  'seeded light': ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  'seeded dark': ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark)),
};

void main() {
  for (final MapEntry(key: name, value: theme) in _themes.entries) {
    testWidgets('$name: cards, sheets and fields stand out; meta text reads at 4.5:1', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final background = theme.scaffoldBackgroundColor;
      final card = RefreshColors.card(context);
      final sheet = RefreshColors.sheet(context);
      final field = RefreshColors.field(context);

      expect(card, isNot(background));
      expect(field, isNot(sheet));
      expect(field, isNot(card));
      expect(field, isNot(background));
      for (final on in [card, sheet, field, background]) {
        expect(RefreshColors.contrast(RefreshColors.meta(context, on: on), on), greaterThanOrEqualTo(4.5));
      }
      // The faint edge is never a full-strength line.
      expect(RefreshColors.faintBorder(context), isNot(theme.colorScheme.onSurface));
      expect(RefreshColors.contrast(theme.colorScheme.onSurface, RefreshColors.tonal(context)), greaterThanOrEqualTo(4.5));
    });
  }

  test('readable moves a colour just far enough for the ratio', () {
    const grey = Color(0xFFBBBBBB);
    final raised = RefreshColors.readable(grey, Colors.black, Colors.white, 4.5);
    expect(RefreshColors.contrast(raised, Colors.white), greaterThanOrEqualTo(4.5));
    expect(RefreshColors.contrast(raised, Colors.white), lessThan(5));
    expect(RefreshColors.readable(Colors.black, Colors.black, Colors.white, 4.5), Colors.black);
  });
}
