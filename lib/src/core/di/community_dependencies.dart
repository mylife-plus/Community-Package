import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../config/community_config.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../data/repositories/identity_repository.dart';
import '../api/api_client.dart';
import '../cache/prefs_cache.dart';
import '../identity/anon_id_source.dart';
import '../identity/device_details.dart';

/// The package's long-lived objects, registered bottom-up in the shared GetX
/// container. Every tag starts with `community_`, so host apps that use GetX
/// themselves (SpaceTime, money) never see a clash.
abstract final class CommunityDependencies {
  static const _configTag = 'community_config';
  static const _identityTag = 'community_identity_repository';
  static const _apiTag = 'community_api';
  static const _cacheTag = 'community_cache';
  static const _feedbackTag = 'community_feedback_repository';
  static const _deviceTag = 'community_device_details';

  /// [httpClient], [anonIdSource] and [deviceDetails] replace the network,
  /// the phone's ID storage and its device details in tests.
  static void register(
    CommunityConfig config, {
    http.Client? httpClient,
    AnonIdSource? anonIdSource,
    DeviceDetailsSource? deviceDetails,
  }) {
    unregister();
    Get.put(config, tag: _configTag, permanent: true);
    final identity = Get.put(
      IdentityRepository(anonIdSource ?? AnonIdSource.forPlatform()),
      tag: _identityTag,
      permanent: true,
    );
    final api = Get.put(
      ApiClient(
        backendUrl: config.backendUrl,
        appId: config.appId,
        anonId: identity.requestAnonId,
        httpClient: httpClient,
      ),
      tag: _apiTag,
      permanent: true,
    );
    final cache = Get.put(PrefsCache(), tag: _cacheTag, permanent: true);
    Get.put(FeedbackRepository(api, cache), tag: _feedbackTag, permanent: true);
    Get.put<DeviceDetailsSource>(
      deviceDetails ?? DeviceDetailsSource.forPlatform(),
      tag: _deviceTag,
      permanent: true,
    );
  }

  /// Removes everything [register] added. Safe to call when nothing is registered.
  static void unregister() {
    Get.delete<DeviceDetailsSource>(tag: _deviceTag, force: true);
    if (Get.isRegistered<FeedbackRepository>(tag: _feedbackTag)) {
      Get.find<FeedbackRepository>(tag: _feedbackTag).dispose();
      Get.delete<FeedbackRepository>(tag: _feedbackTag, force: true);
    }
    Get.delete<PrefsCache>(tag: _cacheTag, force: true);
    Get.delete<ApiClient>(tag: _apiTag, force: true);
    if (Get.isRegistered<IdentityRepository>(tag: _identityTag)) {
      Get.find<IdentityRepository>(tag: _identityTag).dispose();
      Get.delete<IdentityRepository>(tag: _identityTag, force: true);
    }
    Get.delete<CommunityConfig>(tag: _configTag, force: true);
  }

  static CommunityConfig get config => Get.find<CommunityConfig>(tag: _configTag);

  static ApiClient get api => Get.find<ApiClient>(tag: _apiTag);

  static IdentityRepository get identityRepository =>
      Get.find<IdentityRepository>(tag: _identityTag);

  static FeedbackRepository get feedbackRepository =>
      Get.find<FeedbackRepository>(tag: _feedbackTag);

  static DeviceDetailsSource get deviceDetails => Get.find<DeviceDetailsSource>(tag: _deviceTag);
}
