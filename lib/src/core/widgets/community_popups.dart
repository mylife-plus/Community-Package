import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';
import 'community_button.dart';

// The only file that opens raw sheets, dialogs and snackbars. Everything uses
// Flutter's own APIs with the package's context, so host apps need no
// GetMaterialApp.

/// A bottom sheet in the package's style. It grows with its content up to
/// the whole screen below the status bar, so long content must scroll; a
/// Column with an Expanded child fills that height. Dragging the sheet down
/// closes it with null.
Future<T?> showCommunitySheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    // Without this Flutter caps the sheet at 9/16 of the screen height.
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CommunityTokens.sheetRadius)),
    ),
    builder: builder,
  );
}

/// A small menu that drops down from the widget [anchorContext] belongs to,
/// like Flutter's PopupMenuButton: same overlay coordinates
/// (material/popup_menu.dart, PopupMenuButtonState.showButtonMenu), a
/// transparent barrier, and back or a tap outside closes it with null.
/// [builder]'s content keeps its own size, up to the screen.
Future<T?> showCommunityDropdown<T>(BuildContext anchorContext, {required WidgetBuilder builder}) {
  final navigator = Navigator.of(anchorContext);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final button = anchorContext.findRenderObject()! as RenderBox;
  final anchor = Rect.fromPoints(
    button.localToGlobal(Offset.zero, ancestor: overlay),
    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  return navigator.push(
    _DropdownRoute<T>(
      anchor: anchor,
      builder: builder,
      barrierLabel: MaterialLocalizations.of(anchorContext).modalBarrierDismissLabel,
    ),
  );
}

class _DropdownRoute<T> extends PopupRoute<T> {
  _DropdownRoute({required this.anchor, required this.builder, required this.barrierLabel});

  final Rect anchor;
  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final padding = MediaQuery.paddingOf(context);
    return CustomSingleChildLayout(
      delegate: _DropdownLayout(anchor: anchor, padding: padding),
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
}

/// Places the menu just below its anchor, left edges lined up, and keeps it
/// on screen.
class _DropdownLayout extends SingleChildLayoutDelegate {
  _DropdownLayout({required this.anchor, required this.padding});

  /// Gap between the anchor and the menu, and to the screen edges.
  static const _gap = 4.0;
  static const _screenMargin = CommunityTokens.screenPadding;

  final Rect anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final space = constraints.biggest;
    final below = space.height - anchor.bottom - _gap - padding.bottom - _screenMargin;
    final above = anchor.top - _gap - padding.top - _screenMargin;
    return BoxConstraints(
      maxWidth: space.width - _screenMargin * 2,
      maxHeight: math.max(math.max(below, above), 0),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = size.width - _screenMargin - childSize.width;
    final x = anchor.left.clamp(_screenMargin, math.max(maxX, _screenMargin)).toDouble();
    final fitsBelow = anchor.bottom + _gap + childSize.height <= size.height - padding.bottom - _screenMargin;
    final y = fitsBelow ? anchor.bottom + _gap : anchor.top - _gap - childSize.height;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_DropdownLayout oldDelegate) =>
      anchor != oldDelegate.anchor || padding != oldDelegate.padding;
}

/// Closes the sheet or dialog [context] is in, with [result].
void closePopup<T>(BuildContext context, [T? result]) => Navigator.of(context).pop(result);

/// A short message at the bottom of the screen. [bottomClearance] lifts it
/// above buttons at the bottom of a screen's body: the Scaffold only clears
/// its own bottom bar and floating action button.
void showCommunitySnackBar(BuildContext context, String message, {double bottomClearance = 0}) {
  // Material's snackbar colours: the inverse surface stands out from the
  // screen behind it (https://m3.material.io/components/snackbar/specs).
  // Set here because a host theme may pick a background close to its cards
  // (Inventory's dark snackbar was hard to notice on the list).
  final colors = Theme.of(context).colorScheme;
  final content = Text(message, style: TextStyle(color: colors.onInverseSurface));
  final SnackBar snackBar;
  if (bottomClearance > 0) {
    // A margin needs floating behaviour. 15, 5, 15, 10 is Flutter's own
    // default inset (SnackBarThemeData.insetPadding).
    final inset =
        SnackBarTheme.of(context).insetPadding ?? const EdgeInsets.fromLTRB(15, 5, 15, 10);
    snackBar = SnackBar(
      content: content,
      backgroundColor: colors.inverseSurface,
      behavior: SnackBarBehavior.floating,
      margin: inset.copyWith(bottom: inset.bottom + bottomClearance),
    );
  } else {
    snackBar = SnackBar(content: content, backgroundColor: colors.inverseSurface);
  }
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

/// Asks [title] with a red [confirmLabel] and a [cancelLabel]. True only
/// when the user confirms; tapping outside or back counts as cancel.
Future<bool> showCommunityConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CommunityTokens.sheetRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 40,
                runSpacing: 12,
                children: [
                  CommunityButton(
                    label: confirmLabel,
                    destructive: true,
                    onPressed: () => closePopup(dialogContext, true),
                  ),
                  CommunityButton(label: cancelLabel, onPressed: () => closePopup(dialogContext, false)),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

/// Runs [action] behind a blocking loading dialog, the pattern for actions
/// such as submit. The dialog closes however [action] ends; its result or
/// error is passed on.
Future<T> runWithLoading<T>(BuildContext context, Future<T> Function() action) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  unawaited(navigator.push(route));
  try {
    return await action();
  } finally {
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  }
}
