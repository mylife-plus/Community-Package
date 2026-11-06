import 'package:community_package/community_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(CommunityPackage.reset);

  test('config throws before init', () {
    expect(() => CommunityPackage.config, throwsStateError);
  });

  test('init stores the config', () async {
    await CommunityPackage.init(
      const CommunityConfig(
        backendUrl: 'https://community-dev.qureshicreatives.workers.dev',
        appId: 'inventory',
      ),
    );

    expect(CommunityPackage.config.appId, 'inventory');
    expect(
      CommunityPackage.config.backendUrl,
      'https://community-dev.qureshicreatives.workers.dev',
    );
  });
}
