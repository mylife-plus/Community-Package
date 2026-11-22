import 'package:flutter/material.dart';

import '../theme/refresh_style.dart';

/// Buttons of the refreshed look: 48 high, radius 12, with a ripple.
/// Every style is set here, so a host's button themes don't change them.
enum RefreshButtonKind {
  /// Filled with the host's primary colour (Save).
  primary,

  /// Outlined (Cancel).
  secondary,

  /// Tonal in the error colour (Delete, Block).
  destructive,
}

/// The label with a capital first letter. The shared labels are lower
/// case for Figma's tooltips ("save", "cancel"); a visible button reads
/// "Save". Until the rollout changes the labels themselves.
String sentenceCase(String label) =>
    label.isEmpty ? label : label.substring(0, 1).toUpperCase() + label.substring(1);

class RefreshButton extends StatelessWidget {
  const RefreshButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = RefreshButtonKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final RefreshButtonKind kind;
  final IconData? icon;

  static const _padding = 20.0;
  static const _iconSize = 20.0;

  /// Flutter's gap between a button's icon and its label: 8, shrinking to
  /// 4 with larger text (material/text_button.dart, `lerpDouble(8, 4, scale)`),
  /// so 8 never underestimates.
  static const _iconGap = 8.0;

  static TextStyle? _textStyle(BuildContext context) => Theme.of(context).textTheme.labelLarge?.copyWith(
    fontSize: RefreshTokens.bodySize,
    fontWeight: FontWeight.w600,
  );

  /// The width a button needs to show [label] in full, at the user's text
  /// size, so a layout can tell whether it fits.
  static double contentWidth(BuildContext context, String label, {bool hasIcon = false}) {
    final painter = TextPainter(
      text: TextSpan(text: sentenceCase(label), style: _textStyle(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return _padding * 2 + width + (hasIcon ? _iconSize + _iconGap : 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(RefreshTokens.controlRadius));
    final textStyle = _textStyle(context);
    const minimumSize = Size(64, RefreshTokens.minTarget);
    const padding = EdgeInsets.symmetric(horizontal: _padding);
    final style = switch (kind) {
      RefreshButtonKind.primary => FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
        minimumSize: minimumSize,
        padding: padding,
        shape: shape,
        textStyle: textStyle,
        elevation: 0,
      ),
      RefreshButtonKind.secondary => OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.28)),
        minimumSize: minimumSize,
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
      RefreshButtonKind.destructive => TextButton.styleFrom(
        // The error colour, darkened (light) or lightened (dark) just
        // enough to read at 4.5:1 on its own tonal background.
        foregroundColor: RefreshColors.readable(scheme.error, scheme.onSurface, RefreshColors.errorTonal(context), 4.5),
        backgroundColor: RefreshColors.errorTonal(context),
        minimumSize: minimumSize,
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
    };
    final child = Text(sentenceCase(label), maxLines: 1, overflow: TextOverflow.ellipsis);
    final icon = this.icon;
    final iconWidget = icon == null ? null : Icon(icon, size: _iconSize);
    return switch (kind) {
      RefreshButtonKind.primary =>
        iconWidget == null
            ? FilledButton(onPressed: onPressed, style: style, child: child)
            : FilledButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: child),
      RefreshButtonKind.secondary =>
        iconWidget == null
            ? OutlinedButton(onPressed: onPressed, style: style, child: child)
            : OutlinedButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: child),
      RefreshButtonKind.destructive =>
        iconWidget == null
            ? TextButton(onPressed: onPressed, style: style, child: child)
            : TextButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: child),
    };
  }
}

/// A round 48 px icon button of the refreshed look. [tonal] gives it a
/// soft primary background (header actions, an active toolbar button).
class RefreshIconButton extends StatelessWidget {
  const RefreshIconButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.tonal = false,
    this.color,
    this.selected,
    this.iconSize = RefreshTokens.iconSize,
  });

  /// The icon's size inside the 48 px button.
  final double iconSize;

  final String? tooltip;
  final VoidCallback? onPressed;

  /// An [Icon] or any other 22 px mark (the GitHub logo).
  final Widget icon;
  final bool tonal;

  /// The icon colour. Defaults to onSurface.
  final Color? color;

  /// For toggles such as an active filter.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: selected,
      iconSize: iconSize,
      style: IconButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: tonal ? RefreshColors.tonal(context, on: Theme.of(context).scaffoldBackgroundColor) : null,
        minimumSize: const Size.square(RefreshTokens.minTarget),
        fixedSize: const Size.square(RefreshTokens.minTarget),
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: IconTheme.merge(data: IconThemeData(color: foreground), child: icon),
    );
  }
}

/// Two buttons of the refreshed look on a two-column grid, [start] on the
/// left (Cancel) and [end] on the right (the main action). When a label
/// doesn't fit half the width at the user's text size, both go full width,
/// stacked in the same order.
class RefreshButtonPair extends StatelessWidget {
  const RefreshButtonPair({super.key, required this.start, required this.end});

  final RefreshButton start;
  final RefreshButton end;

  /// Across and down.
  static const gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - gap) / 2;
        final fits = [start, end].every(
          (b) => RefreshButton.contentWidth(context, b.label, hasIcon: b.icon != null) <= half,
        );
        if (fits) {
          return Row(
            children: [
              Expanded(child: start),
              const SizedBox(width: gap),
              Expanded(child: end),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [start, const SizedBox(height: gap), end],
        );
      },
    );
  }
}
