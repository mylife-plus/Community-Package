import 'package:flutter/widgets.dart';

import 'config/community_config.dart';
import 'core/di/community_dependencies.dart';
import 'core/navigation/community_navigator.dart';

/// Entry point for host apps.
abstract final class CommunityPackage {
  static CommunityConfig? _config;

  /// Sets up the package. Call once at startup, before opening any screen.
  /// Does no network work, so it doesn't slow down app start.
  static Future<void> init(CommunityConfig config) async {
    _config = config;
    CommunityDependencies.register(config);
  }

  /// The config passed to [init].
  ///
  /// Throws a [StateError] when [init] has not been called yet.
  static CommunityConfig get config {
    final config = _config;
    if (config == null) {
      throw StateError('Call CommunityPackage.init before using the package.');
    }
    return config;
  }

  /// Opens the community screens full screen, from the host's Settings.
  static Future<void> openCommunity(BuildContext context) {
    if (_config == null) {
      throw StateError('Call CommunityPackage.init before opening the community screens.');
    }
    return CommunityNavigator.open(context, initialRoute: CommunityRoutes.feedbackList);
  }

  @visibleForTesting
  static void reset() {
    _config = null;
    CommunityDependencies.unregister();
  }
}
