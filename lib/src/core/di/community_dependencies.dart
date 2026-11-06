import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../config/community_config.dart';
import '../../data/repositories/feedback_repository.dart';
import '../api/api_client.dart';
import '../cache/prefs_cache.dart';

/// The package's long-lived objects, registered bottom-up in the shared GetX
/// container. Every tag starts with `community_`, so host apps that use GetX
/// themselves (SpaceTime, money) never see a clash.
abstract final class CommunityDependencies {
  static const _apiTag = 'community_api';
  static const _cacheTag = 'community_cache';
  static const _feedbackTag = 'community_feedback_repository';

  /// [httpClient] replaces the network in tests.
  static void register(CommunityConfig config, {http.Client? httpClient}) {
    unregister();
    final api = Get.put(
      ApiClient(backendUrl: config.backendUrl, appId: config.appId, httpClient: httpClient),
      tag: _apiTag,
      permanent: true,
    );
    final cache = Get.put(PrefsCache(), tag: _cacheTag, permanent: true);
    Get.put(FeedbackRepository(api, cache), tag: _feedbackTag, permanent: true);
  }

  /// Removes everything [register] added. Safe to call when nothing is registered.
  static void unregister() {
    if (Get.isRegistered<FeedbackRepository>(tag: _feedbackTag)) {
      Get.find<FeedbackRepository>(tag: _feedbackTag).dispose();
      Get.delete<FeedbackRepository>(tag: _feedbackTag, force: true);
    }
    Get.delete<PrefsCache>(tag: _cacheTag, force: true);
    Get.delete<ApiClient>(tag: _apiTag, force: true);
  }

  static ApiClient get api => Get.find<ApiClient>(tag: _apiTag);

  static FeedbackRepository get feedbackRepository =>
      Get.find<FeedbackRepository>(tag: _feedbackTag);
}
