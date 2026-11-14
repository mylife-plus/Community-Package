import 'package:flutter/material.dart';

/// Figma's inner shadow on chips and header buttons: a light rim inside the
/// edge, strongest at the top. Paints over the fill of the box around it
/// and under [child].
///
/// Flutter's BoxShadow has no inset option
/// (https://github.com/flutter/flutter/issues/18636), so the shadow is a
/// blurred ring around the box, clipped to it. Measured on the heart chip
/// (Settings-15): onSurface at 25%, 1 down, blur 4 (sigma 2).
class InnerShadow extends StatelessWidget {
  const InnerShadow({super.key, required this.radius, this.blur = 4, required this.child});

  final double radius;

  /// Figma's blur value.
  final double blur;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InnerShadowPainter(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
        radius: radius,
        sigma: blur / 2,
      ),
      child: child,
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({required this.color, required this.radius, required this.sigma});

  static const _offset = Offset(0, 1);

  final Color color;
  final double radius;
  final double sigma;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(sigma * 4 + 1)),
      Path()..addRRect(box.shift(_offset)),
    );
    canvas
      ..save()
      ..clipRRect(box)
      ..drawPath(ring, Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma))
      ..restore();
  }

  @override
  bool shouldRepaint(_InnerShadowPainter old) =>
      old.color != color || old.radius != radius || old.sigma != sigma;
}
