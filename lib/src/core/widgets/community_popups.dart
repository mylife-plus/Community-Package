import 'package:flutter/material.dart';

import '../theme/community_tokens.dart';

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

/// A short message at the bottom of the screen.
void showCommunitySnackBar(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
