import 'package:flutter/foundation.dart';

import 'config/community_config.dart';

/// Entry point for host apps.
abstract final class CommunityPackage {
  static CommunityConfig? _config;

  /// Sets up the package. Call once at startup, before opening any screen.
  static Future<void> init(CommunityConfig config) async {
    _config = config;
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

  @visibleForTesting
  static void reset() => _config = null;
}
