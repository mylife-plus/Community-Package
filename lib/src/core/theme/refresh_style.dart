import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The refreshed look (design refresh, proof of concept on Feedback detail
/// and Edit Comment). Figma stays the wireframe for layout and flow; these
/// are the visual values: an 8 pt grid, softer radii, filled fields, real
/// buttons and 48 px touch targets.
abstract final class RefreshTokens {
  static const screenPadding = 16.0;
  static const cardPadding = 16.0;
  static const cardGap = 12.0;
  static const sheetPadding = 24.0;

  static const cardRadius = 16.0;
  static const controlRadius = 12.0;
  static const sheetRadius = 24.0;

  /// Buttons, fields and every tap target.
  static const minTarget = 48.0;

  /// The header with room for 48 px icon buttons.
  static const headerHeight = 56.0;

  static const titleSize = 17.0;
  static const bodySize = 15.0;
  static const bodyLineHeight = 1.4;
  static const metaSize = 13.0;

  static const focusBorderWidth = 1.5;
  static const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const iconSize = 22.0;

  static const expandDuration = Duration(milliseconds: 220);
  static const expandCurve = Curves.easeInOutCubic;

  static TextStyle? title(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle? body(BuildContext context, {Color? color, FontWeight weight = FontWeight.w400}) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: bodySize,
        height: bodyLineHeight,
        fontWeight: weight,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Age, counts and other secondary text, at 4.5:1 or more on [on].
  static TextStyle? meta(BuildContext context, {Color? on, Color? color, FontWeight weight = FontWeight.w400}) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: metaSize,
        fontWeight: weight,
        color: color ?? RefreshColors.meta(context, on: on),
      );
}

/// Turns the refreshed look on for the shared widgets below it. Routes
/// (sheets, menus) don't inherit it: a sheet that should be refreshed wraps
/// its own content.
class CommunityRefresh extends InheritedWidget {
  const CommunityRefresh({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CommunityRefresh>() != null;

  @override
  bool updateShouldNotify(CommunityRefresh oldWidget) => false;
}

/// Surface layers of the refreshed look, from the host's colour scheme.
///
/// Hosts that build their [ColorScheme] by hand (Inventory, SpaceTime)
/// leave the surfaceContainer roles at `surface` and outlineVariant at
/// `onSurface` (Flutter's ColorScheme constructor defaults). Then the
/// layers are mixed from onSurface over the screen background instead, so
/// cards and fields still stand out and borders stay faint.
abstract final class RefreshColors {
  /// Cards: surfaceContainerLow.
  static Color card(BuildContext context) => _layer(context, (s) => s.surfaceContainerLow, 0.05);

  /// Sheets: surfaceContainerHigh.
  static Color sheet(BuildContext context) => _layer(context, (s) => s.surfaceContainerHigh, 0.08);

  /// Filled text fields: surfaceContainerHighest.
  static Color field(BuildContext context) => _layer(context, (s) => s.surfaceContainerHighest, 0.12);

  /// A faint card edge: outlineVariant, or onSurface at 10%.
  static Color faintBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final set = scheme.outlineVariant != scheme.onSurface && scheme.outlineVariant != scheme.outline;
    return set ? scheme.outlineVariant.withValues(alpha: 0.6) : scheme.onSurface.withValues(alpha: 0.10);
  }

  /// Tonal chips and icon buttons: primary at 14% over [on] (default the
  /// card), so it works with any host primary.
  static Color tonal(BuildContext context, {Color? on}) =>
      Color.alphaBlend(Theme.of(context).colorScheme.primary.withValues(alpha: 0.14), on ?? card(context));

  /// Tonal background for destructive buttons: error at 12%.
  static Color errorTonal(BuildContext context, {Color? on}) =>
      Color.alphaBlend(Theme.of(context).colorScheme.error.withValues(alpha: 0.12), on ?? sheet(context));

  /// Secondary text: onSurfaceVariant, raised toward onSurface until it
  /// reaches 4.5:1 on [on] (default the card). WCAG 1.4.3:
  /// https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
  static Color meta(BuildContext context, {Color? on}) {
    final scheme = Theme.of(context).colorScheme;
    final background = on ?? card(context);
    // A hand-built scheme leaves onSurfaceVariant at onSurface: start from
    // a softer mix instead.
    final start = scheme.onSurfaceVariant == scheme.onSurface
        ? Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.68), background)
        : scheme.onSurfaceVariant;
    return readable(start, scheme.onSurface, background, 4.5);
  }

  /// [color], moved toward [strongest] just enough for [ratio] on
  /// [background].
  static Color readable(Color color, Color strongest, Color background, double ratio) {
    if (contrast(color, background) >= ratio) return color;
    if (contrast(strongest, background) < ratio) return strongest;
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (contrast(Color.lerp(color, strongest, mid)!, background) >= ratio) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return Color.lerp(color, strongest, high)!;
  }

  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static Color _layer(BuildContext context, Color Function(ColorScheme) role, double mix) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    final value = role(scheme);
    if (value != scheme.surface && value != background) return value;
    return Color.alphaBlend(scheme.onSurface.withValues(alpha: mix), background);
  }
}
