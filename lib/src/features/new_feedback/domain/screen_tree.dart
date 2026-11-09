import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../config/screen_node.dart';
import '../../../core/navigation/community_screens.dart';
import '../../../core/utils/formatters.dart';

/// One row of the screen picker: a screen, how deep it sits, and the names
/// from the top down to it.
@immutable
class ScreenChoice {
  const ScreenChoice({required this.path, this.nodes = const []});

  /// Names from the top-level screen down to this one, as saved.
  final List<String> path;

  /// The screens of [path], for their titles. Empty shows the names.
  final List<ScreenNode> nodes;

  /// The titles of [path] in the app's language.
  List<String> labels(BuildContext context) => [
    for (var i = 0; i < path.length; i++)
      i < nodes.length ? screenLabel(context, nodes[i]) : path[i],
  ];

  /// This screen's title in the app's language.
  String label(BuildContext context) => labels(context).last;

  String get name => path.last;

  /// 0 for a top-level screen.
  int get depth => path.length - 1;

  /// The path as saved with a Problem.
  String get savedPath => path.join(screenPathSeparator);

  @override
  bool operator ==(Object other) => other is ScreenChoice && listEquals(other.path, path);

  @override
  int get hashCode => Object.hashAll(path);
}

/// Every screen of [roots], parents before their children, in the order
/// given.
List<ScreenChoice> flattenScreens(List<ScreenNode> roots) {
  final rows = <ScreenChoice>[];
  void visit(ScreenNode node, List<ScreenNode> parents) {
    final nodes = [...parents, node];
    rows.add(ScreenChoice(path: [for (final n in nodes) n.name], nodes: nodes));
    for (final child in node.children) {
      visit(child, nodes);
    }
  }

  for (final root in roots) {
    visit(root, const []);
  }
  return rows;
}

/// The screens the picker offers: the host's, then [communityScreens].
/// Empty when the host gave none, and then the form asks no screen.
List<ScreenChoice> pickerScreens(List<ScreenNode> hostScreens) =>
    hostScreens.isEmpty ? const [] : flattenScreens([...hostScreens, communityScreens]);
