import 'dart:async';

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

/// Closes the sheet or dialog [context] is in, with [result].
void closePopup<T>(BuildContext context, [T? result]) => Navigator.of(context).pop(result);

/// A short message at the bottom of the screen. [bottomClearance] lifts it
/// above buttons at the bottom of a screen's body: the Scaffold only clears
/// its own bottom bar and floating action button.
void showCommunitySnackBar(BuildContext context, String message, {double bottomClearance = 0}) {
  final SnackBar snackBar;
  if (bottomClearance > 0) {
    // A margin needs floating behaviour. 15, 5, 15, 10 is Flutter's own
    // default inset (SnackBarThemeData.insetPadding).
    final inset =
        SnackBarTheme.of(context).insetPadding ?? const EdgeInsets.fromLTRB(15, 5, 15, 10);
    snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: inset.copyWith(bottom: inset.bottom + bottomClearance),
    );
  } else {
    snackBar = SnackBar(content: Text(message));
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
