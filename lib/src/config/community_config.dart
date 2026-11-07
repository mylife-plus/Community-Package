import 'screen_node.dart';

/// Settings a host app passes to `CommunityPackage.init`.
class CommunityConfig {
  const CommunityConfig({
    required this.backendUrl,
    required this.appId,
    this.privacyPolicyUrl,
    this.screens = const [],
  });

  /// Base URL of the community Worker, without the `/v1` prefix.
  /// For example `https://community-dev.qureshicreatives.workers.dev`.
  final String backendUrl;

  /// The app's ID on the backend: `inventory`, `spacetime` or `money`.
  final String appId;

  /// The full Privacy Policy, linked from the privacy notice. Without it the
  /// notice leaves out the link and the sentence around it.
  final String? privacyPolicyUrl;

  /// The app's screens, top level first, for the Problem form's screen
  /// picker. Empty: the form asks no screen.
  final List<ScreenNode> screens;
}
