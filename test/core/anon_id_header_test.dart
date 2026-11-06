import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/core/identity/anon_id_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

/// No ID may leave the phone before the user agreed to the privacy notice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = CommunityConfig(backendUrl: 'https://example.com', appId: 'inventory');
  const androidId = '9774d56d682e549c';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(CommunityDependencies.unregister);

  Future<FakeBackend> register(AnonIdSource source) async {
    final backend = FakeBackend();
    CommunityDependencies.register(config, httpClient: backend.client, anonIdSource: source);
    return backend;
  }

  Future<void> loadList(FakeBackend backend) async {
    backend.answer(pageJson([1]));
    await CommunityDependencies.feedbackRepository.getFeedbackList(forceRefresh: true);
  }

  test('Android: no X-Anon-Id before Agree, the derived ID after', () async {
    final backend = await register(AndroidAnonIdSource(androidId: () async => androidId));

    await loadList(backend);
    expect(backend.requests.last.headers.containsKey('X-Anon-Id'), isFalse);

    await CommunityDependencies.identityRepository.agreeToPrivacy();
    await loadList(backend);
    expect(
      backend.requests.last.headers['X-Anon-Id'],
      sha256Uuid('community_package:$androidId'),
    );
  });

  test('iOS: no X-Anon-Id before Agree, the Keychain ID after', () async {
    final backend = await register(KeychainAnonIdSource());

    await loadList(backend);
    expect(backend.requests.last.headers.containsKey('X-Anon-Id'), isFalse);

    final identity = await CommunityDependencies.identityRepository.agreeToPrivacy();
    await loadList(backend);
    expect(backend.requests.last.headers['X-Anon-Id'], identity.anonId);
  });

  test('Android: after a restart the agreed ID is sent from the first request', () async {
    await AndroidAnonIdSource(androidId: () async => androidId).create();
    final backend = await register(AndroidAnonIdSource(androidId: () async => androidId));

    await loadList(backend);

    expect(
      backend.requests.single.headers['X-Anon-Id'],
      sha256Uuid('community_package:$androidId'),
    );
  });
}
