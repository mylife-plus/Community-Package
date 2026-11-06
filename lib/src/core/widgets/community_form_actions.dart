import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';

/// The ✗ (cancel) and ✓ (submit) buttons at the bottom of a form.
/// A null [onSubmit] shows the ✓ dimmed and ignores taps.
class CommunityFormActions extends StatelessWidget {
  const CommunityFormActions({
    super.key,
    required this.cancelLabel,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  /// Not tuned yet: how faint the ✓ is while the form can't be sent.
  static const disabledOpacity = 0.35;

  /// How far a snackbar must rise to clear these buttons, on a form that
  /// keeps them at the bottom of its body with
  /// [CommunityTokens.actionsBottomGap] under them. A floating snackbar
  /// already sits above the bottom inset (Scaffold's layout), so only the
  /// part of the gap that the inset doesn't cover is added.
  static double snackBarClearance(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return CommunityTokens.actionButtonSize.height +
        math.max(0.0, CommunityTokens.actionsBottomGap - inset);
  }

  final String cancelLabel;
  final String submitLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final submit = CommunityColors.of(context).submit;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          label: cancelLabel,
          onPressed: onCancel,
          icon: CustomPaint(size: const Size(20, 20), painter: _CrossPainter(error)),
        ),
        const SizedBox(width: CommunityTokens.actionButtonGap),
        _ActionButton(
          label: submitLabel,
          onPressed: onSubmit,
          icon: Opacity(
            opacity: onSubmit == null ? disabledOpacity : 1,
            child: CustomPaint(size: const Size(30, 27), painter: _CheckPainter(submit)),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed, required this.icon});

  final String label;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(CommunityTokens.actionButtonRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.fromSize(
              size: CommunityTokens.actionButtonSize,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

// Both marks are drawn from the shapes in the Figma export: 4 px strokes
// with square ends.
const _strokeWidth = 4.0;

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth;
    // Inset so the square ends stay inside the box.
    const inset = _strokeWidth / 2 / 1.4142;
    canvas
      ..drawLine(const Offset(inset, inset), Offset(size.width - inset, size.height - inset), paint)
      ..drawLine(Offset(size.width - inset, inset), Offset(inset, size.height - inset), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;
    // Points for a 30 × 27 box, scaled to [size].
    final sx = size.width / 30;
    final sy = size.height / 27;
    final path = Path()
      ..moveTo(2.5 * sx, 13.5 * sy)
      ..lineTo(13.8 * sx, 23.2 * sy)
      ..lineTo(28.5 * sx, 1.5 * sy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
