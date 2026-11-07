/// One screen of the host app, for the screen picker of the Problem form.
///
/// [name] is saved as written, so write it in English: the admin and the
/// developers then read the same path whatever language the user has.
class ScreenNode {
  const ScreenNode(this.name, {this.children = const []});

  final String name;

  /// Screens opened from this one.
  final List<ScreenNode> children;
}
