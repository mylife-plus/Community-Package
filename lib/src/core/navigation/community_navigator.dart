import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/community_home/presentation/community_home_screen.dart';
import '../../features/feedback_list/presentation/feedback_list_screen.dart';
import '../../features/new_feedback/presentation/new_feedback_screen.dart';
import '../di/community_dependencies.dart';
import '../l10n/community_localizations.dart';
import '../widgets/community_popups.dart';

/// Route names inside the package's own Navigator.
abstract final class CommunityRoutes {
  static const home = '/community';
  static const feedbackList = '/feedback';
  static const newFeedback = '/feedback/new';
}

/// The package's nested Navigator. Host apps never see these routes; they
/// open the flow with [CommunityNavigator.open].
class CommunityNavigator extends StatefulWidget {
  const CommunityNavigator({super.key, required this.initialRoute});

  final String initialRoute;

  /// Opens the community flow full screen, above the host's bottom bars.
  static Future<void> open(BuildContext context, {required String initialRoute}) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => CommunityNavigator(initialRoute: initialRoute)),
    );
  }

  /// All Feedback, on top of the current package screen.
  static Future<void> openFeedbackList(BuildContext context) =>
      Navigator.of(context).pushNamed(CommunityRoutes.feedbackList);

  /// New Feedback, on top of the current package screen.
  static Future<void> openNewFeedback(BuildContext context) =>
      Navigator.of(context).pushNamed(CommunityRoutes.newFeedback);

  /// After a post from New Feedback: back to the list it was opened from,
  /// or, when the flow started on New Feedback, the list in its place.
  static void showFeedbackListAfterPost(BuildContext context) {
    final inner = Navigator.of(context);
    if (inner.canPop()) {
      inner.pop();
    } else {
      inner.pushReplacementNamed(CommunityRoutes.feedbackList);
    }
  }

  /// Opens [url] in the browser or the app that handles it. Tells the user
  /// when nothing could open it.
  static Future<void> openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Exception catch (e) {
        debugPrint('community: could not open $url: $e');
      }
    }
    if (!opened && context.mounted) {
      showCommunitySnackBar(context, CommunityLocalizations.of(context).linkFailed);
    }
  }

  /// Back from a package screen: pops inside the package, or closes the
  /// whole flow from its first screen.
  static void back(BuildContext context) {
    final inner = Navigator.of(context);
    if (inner.canPop()) {
      inner.pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<CommunityNavigator> createState() => _CommunityNavigatorState();
}

class _CommunityNavigatorState extends State<CommunityNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Content is requested in the reader's app language, even where the
    // package has no labels for it yet.
    CommunityDependencies.api.languageCode = Localizations.localeOf(context).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    // System back pops the inner Navigator first; from its first route the
    // outer route (this whole flow) pops as usual.
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        initialRoute: widget.initialRoute,
        // One route per flow start. The default splits '/feedback' into
        // '/' and '/feedback' and pushes both.
        onGenerateInitialRoutes: (_, name) => [_route(RouteSettings(name: name))],
        onGenerateRoute: _route,
      ),
    );
  }

  static Route<void> _route(RouteSettings settings) {
    switch (settings.name) {
      case CommunityRoutes.feedbackList:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const FeedbackListScreen(),
        );
      case CommunityRoutes.newFeedback:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const NewFeedbackScreen(),
        );
      case CommunityRoutes.home:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const CommunityHomeScreen(),
        );
    }
  }
}
