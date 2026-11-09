import 'package:flutter/widgets.dart';

/// One screen of the host app, for the screen picker of the Problem form.
///
/// [name] is saved as written, so write it in English: the admin and the
/// developers then read the same path whatever language the user has.
/// [label] is what the user sees, in the app's language.
class ScreenNode {
  const ScreenNode(this.name, {this.children = const [], this.label});

  final String name;

  /// The screen's title in the app's current language, for the picker and
  /// for paths on Problem cards. Without it, [name] is shown.
  final String Function(BuildContext context)? label;

  /// Screens opened from this one.
  final List<ScreenNode> children;
}
