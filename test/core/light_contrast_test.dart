import 'dart:math' as math;

import 'package:community_package/src/core/theme/community_tokens.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Inventory's light theme as it shows on the device (sampled from the
  // screenshots), and Flutter's default light theme.
  final themes = {
    'Inventory light': ThemeData(
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0B1A28),
        primary: Color(0xFF2F6F9F),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F5F8),
    ),
    'Flutter light': ThemeData(),
  };

  Future<BuildContext> pump(WidgetTester tester, ThemeData theme) async {
    late BuildContext context;
    final probe = Builder(
      builder: (c) {
        context = c;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(MaterialApp(theme: theme, home: probe));
    return context;
  }

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final backgrounds = [theme.colorScheme.surface, theme.scaffoldBackgroundColor];

    testWidgets('$name: placeholders, captions and muted text are at least 4.5:1', (tester) async {
      final context = await pump(tester, theme);
      for (final color in [
        CommunityColors.placeholder(context),
        CommunityColors.caption(context),
        CommunityColors.muted(context),
        CommunityColors.deviceLine(context),
      ]) {
        for (final bg in backgrounds) {
          expect(contrast(color, bg), greaterThanOrEqualTo(4.5));
        }
      }
    });

    testWidgets('$name: field and comment field borders are at least 3:1', (tester) async {
      final context = await pump(tester, theme);
      for (final color in [CommunityColors.fieldBorder(context), CommunityColors.commentFieldBorder(context)]) {
        for (final bg in backgrounds) {
          expect(contrast(color, bg), greaterThanOrEqualTo(3));
        }
      }
    });

    testWidgets('$name: grey icons are at least 3:1', (tester) async {
      final context = await pump(tester, theme);
      for (final color in [CommunityColors.icon(context), CommunityColors.commentAdd(context)]) {
        for (final bg in backgrounds) {
          expect(contrast(color, bg), greaterThanOrEqualTo(3));
        }
      }
    });

    testWidgets('$name: "in progress" text is at least 4.5:1', (tester) async {
      final context = await pump(tester, theme);
      final color = CommunityColors.of(context).status(FeedbackStatus.inProgress);
      for (final bg in backgrounds) {
        expect(contrast(color, bg), greaterThanOrEqualTo(4.5));
      }
    });
  }

  testWidgets('dark mode keeps Figma\'s greys', (tester) async {
    final context = await pump(
      tester,
      ThemeData(colorScheme: const ColorScheme.dark(surface: Color(0xFF000000), onSurface: Color(0xFFFFFFFF))),
    );
    expect(CommunityColors.placeholder(context).toARGB32(), 0xFF898989);
    expect(CommunityColors.caption(context).toARGB32(), 0xFF909090);
    expect(CommunityColors.commentFieldBorder(context).toARGB32(), 0xFF404040);
    expect(CommunityColors.muted(context), const Color(0xFFFFFFFF).withValues(alpha: 0.6));
  });
}
