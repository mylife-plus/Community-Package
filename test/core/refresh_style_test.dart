import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/host_themes.dart';


void main() {
  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
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
