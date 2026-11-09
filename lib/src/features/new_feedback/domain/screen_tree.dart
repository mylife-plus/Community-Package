import 'package:flutter/foundation.dart';

import '../../../config/screen_node.dart';
import '../../../core/utils/formatters.dart';

/// The package's own screens, added after the host app's so a problem in
/// the feedback screens can be reported too. English, like the host's names.
/// Later screens (feedback detail, My History, ...) join as they are built.
const communityScreens = ScreenNode(
  'Community',
  children: [
    ScreenNode('Community App'),
    ScreenNode('All Feedback'),
    ScreenNode('Feedback Detail'),
    ScreenNode('New Feedback'),
  ],
);

/// One row of the screen picker: a screen, how deep it sits, and the names
/// from the top down to it.
@immutable
class ScreenChoice {
  const ScreenChoice({required this.path});

  /// From the top-level screen down to this one.
  final List<String> path;

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
  void visit(ScreenNode node, List<String> parents) {
    final path = [...parents, node.name];
    rows.add(ScreenChoice(path: path));
    for (final child in node.children) {
      visit(child, path);
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
