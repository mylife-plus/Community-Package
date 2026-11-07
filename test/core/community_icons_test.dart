import 'dart:io';

import 'package:community_package/src/core/theme/community_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final icon in CommunityIcons.all) {
    test('$icon is bundled and parses', () async {
      // The test bundle (build/unit_test_assets) keeps files that were
      // deleted since the last run, so check the file itself first.
      expect(File(icon).existsSync(), isTrue, reason: '$icon is missing');

      // The same loader SvgPicture.asset uses: it reads
      // packages/community_package/<path> from the asset bundle and parses it.
      final bytes = await SvgAssetLoader(icon, packageName: CommunityIcons.package).loadBytes(null);

      expect(bytes.lengthInBytes, greaterThan(0));
    });
  }

  test('every SVG the package draws is listed in CommunityIcons', () {
    final svgPath = RegExp(r'''['"]([^'"\s]+\.svg)['"]''');
    final unlisted = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('community_icons.dart'))
          for (final match in svgPath.allMatches(file.readAsStringSync())) '${file.path}: ${match[1]}',
    ];

    expect(unlisted, isEmpty, reason: 'Add the icon to CommunityIcons and use the constant.');
  });
}
