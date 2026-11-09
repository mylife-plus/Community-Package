import 'package:flutter/widgets.dart';

import '../../config/screen_node.dart';
import '../l10n/community_localizations.dart';

/// The package's own screens, added after the host app's so a problem in
/// the feedback screens can be reported too. Names in English, like the
/// host's; labels in the package's languages. Later screens (My History,
/// ...) join as they are built.
const communityScreens = ScreenNode(
  'Community',
  label: _community,
  children: [
    ScreenNode('Community App', label: _communityApp),
    ScreenNode('All Feedback', label: _allFeedback),
    ScreenNode('Feedback Detail', label: _feedbackDetail),
    ScreenNode('New Feedback', label: _newFeedback),
  ],
);

String _community(BuildContext c) => CommunityLocalizations.of(c).screenCommunity;
String _communityApp(BuildContext c) => CommunityLocalizations.of(c).communityTitle;
String _allFeedback(BuildContext c) => CommunityLocalizations.of(c).screenAllFeedback;
String _feedbackDetail(BuildContext c) => CommunityLocalizations.of(c).screenFeedbackDetail;
String _newFeedback(BuildContext c) => CommunityLocalizations.of(c).screenNewFeedback;

/// [node]'s title in the app's language, else its saved name.
String screenLabel(BuildContext context, ScreenNode node) => node.label?.call(context) ?? node.name;

/// The host's screen tree, for showing saved paths in the app's language.
/// Set once around the package's screens; empty (names as saved) without it.
class CommunityScreens extends InheritedWidget {
  const CommunityScreens({super.key, required this.screens, required super.child});

  final List<ScreenNode> screens;

  static List<ScreenNode> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommunityScreens>()?.screens ?? const [];

  @override
  bool updateShouldNotify(CommunityScreens oldWidget) => !identical(oldWidget.screens, screens);
}

/// The titles for a saved path ([names], top first), looked up in [roots]
/// and [communityScreens]. From the first name not found, the rest show as
/// saved: a screen renamed or removed since keeps its old English name.
List<String> screenPathLabels(BuildContext context, List<String> names, List<ScreenNode> roots) {
  final labels = <String>[];
  List<ScreenNode>? level = [...roots, communityScreens];
  for (final name in names) {
    ScreenNode? match;
    for (final node in level ?? const <ScreenNode>[]) {
      if (node.name == name) {
        match = node;
        break;
      }
    }
    if (match == null) {
      labels.add(name);
      level = null;
    } else {
      labels.add(screenLabel(context, match));
      level = match.children;
    }
  }
  return labels;
}
