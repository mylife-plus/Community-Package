import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/community_icons.dart';
import '../theme/community_tokens.dart';
import '../theme/refresh_style.dart';
import 'refresh_buttons.dart';

/// The ✗ (cancel) and ✓ (submit) buttons at the bottom of a form, with an
/// optional red 🗑 (delete) between them (Settings-12).
/// A null [onSubmit] shows the ✓ dimmed and ignores taps.
class CommunityFormActions extends StatelessWidget {
  const CommunityFormActions({
    super.key,
    required this.cancelLabel,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
    this.deleteLabel,
    this.onDelete,
  });

  /// Not tuned yet: how faint the ✓ is while the form can't be sent.
  static const disabledOpacity = 0.35;

  /// The 🗑 takes taps a little outside its 43 × 42 box, so the tap area is
  /// 44 × 44. The gaps beside it are shorter by the same amount, so nothing
  /// moves.
  static const smallButtonTapInset = EdgeInsets.symmetric(horizontal: 0.5, vertical: 1);
  static const _gapToSmall = CommunityTokens.deleteButtonGap - 0.5;

  /// How far a snackbar must rise to clear these buttons, on a form that
  /// keeps them at the bottom of its body with
  /// [CommunityTokens.actionsBottomGap] under them. A floating snackbar
  /// already sits above the bottom inset (Scaffold's layout), so only the
  /// part of the gap that the inset doesn't cover is added.
  static double snackBarClearance(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final height = CommunityRefresh.of(context) ? RefreshTokens.minTarget : CommunityTokens.actionButtonSize.height;
    return height + math.max(0.0, CommunityTokens.actionsBottomGap - inset);
  }

  final String cancelLabel;
  final String submitLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  /// The 🗑 between ✗ and ✓. Hidden when null.
  final String? deleteLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (CommunityRefresh.of(context)) return _refreshed(context);
    final colors = CommunityColors.of(context);
    final onDelete = this.onDelete;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          label: cancelLabel,
          onPressed: onCancel,
          icon: CustomPaint(size: const Size(20, 20), painter: _CrossPainter(colors.cancel)),
        ),
        if (onDelete == null)
          const SizedBox(width: CommunityTokens.actionButtonGap)
        else ...[
          const SizedBox(width: _gapToSmall),
          _DeleteButton(label: deleteLabel ?? '', onPressed: onDelete),
          const SizedBox(width: _gapToSmall),
        ],
        _ActionButton(
          label: submitLabel,
          onPressed: onSubmit,
          icon: Opacity(
            opacity: onSubmit == null ? disabledOpacity : 1,
            child: CustomPaint(size: const Size(30, 27), painter: _CheckPainter(colors.submit)),
          ),
        ),
      ],
    );
  }
}

/// The gap between the refreshed buttons, across and down.
const _gridGap = 12.0;

extension on CommunityFormActions {
  /// The refreshed look: Cancel (outlined) and Save (filled, with a check)
  /// side by side; Delete on its own row below, full width, in the error
  /// colour, away from Save.
  Widget _refreshed(BuildContext context) {
    final onDelete = this.onDelete;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: RefreshButton(label: cancelLabel, onPressed: onCancel, kind: RefreshButtonKind.secondary),
            ),
            const SizedBox(width: _gridGap),
            Expanded(
              child: RefreshButton(label: submitLabel, onPressed: onSubmit, icon: Icons.check_rounded),
            ),
          ],
        ),
        if (onDelete != null) ...[
          const SizedBox(height: 16),
          RefreshButton(
            label: deleteLabel ?? '',
            onPressed: onDelete,
            kind: RefreshButtonKind.destructive,
            icon: Icons.delete_outline_rounded,
          ),
        ],
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CommunityTokens.actionButtonRadius),
            boxShadow: const [CommunityTokens.actionButtonShadow],
          ),
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
      ),
    );
  }
}

/// The red 🗑 button: smaller than ✗ and ✓, in the theme's error colour,
/// with Figma's outline trash.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        // A tap on the box itself goes to its InkWell (the ripple); a tap
        // just outside it to the GestureDetector.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Padding(
            padding: CommunityFormActions.smallButtonTapInset,
            child: Material(
              color: scheme.error,
              borderRadius: BorderRadius.circular(CommunityTokens.actionButtonRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox.fromSize(
                  size: CommunityTokens.deleteButtonSize,
                  child: Center(
                    child: SvgPicture.asset(
                      CommunityIcons.trash,
                      package: CommunityIcons.package,
                      width: 20,
                      height: 22,
                      colorFilter: ColorFilter.mode(scheme.onError, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
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
