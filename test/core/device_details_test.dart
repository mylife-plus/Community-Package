import 'package:community_package/src/core/identity/device_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iosModelName', () {
    test('uses the name device_info_plus knows', () {
      expect(iosModelName(modelName: 'iPhone 15 Pro', machine: 'iPhone16,1', model: 'iPhone'), 'iPhone 15 Pro');
    });

    test('names 2026 models device_info_plus 11 does not know', () {
      expect(iosModelName(modelName: 'Unknown device', machine: 'iPhone19,2', model: 'iPhone'), 'iPhone 18 Pro');
      expect(iosModelName(modelName: 'Unknown device', machine: 'iPhone18,5', model: 'iPhone'), 'iPhone 17e');
    });

    test('the map wins over the plugin name', () {
      expect(iosModelName(modelName: 'iPhone 13 Mini', machine: 'iPhone14,4', model: 'iPhone'), 'iPhone 13 mini');
    });

    test('falls back to the identifier for models newer than both lists', () {
      expect(iosModelName(modelName: 'Unknown device', machine: 'iPhone20,1', model: 'iPhone'), 'iPhone20,1');
    });

    test('falls back to the plain model when there is no identifier', () {
      expect(iosModelName(modelName: 'Unknown device', machine: 'arm64', model: 'iPhone'), 'iPhone');
    });

    test('is null when nothing is known', () {
      expect(iosModelName(modelName: '', machine: 'arm64', model: ''), isNull);
    });
  });

  group('androidModelName', () {
    test('puts the maker before the model', () {
      expect(androidModelName(manufacturer: 'Google', model: 'Pixel 8'), 'Google Pixel 8');
      expect(androidModelName(manufacturer: 'samsung', model: 'SM-S918B'), 'Samsung SM-S918B');
    });

    test('does not repeat a maker the model already names', () {
      expect(androidModelName(manufacturer: 'OnePlus', model: 'OnePlus 12'), 'OnePlus 12');
    });

    test('uses whichever part is known', () {
      expect(androidModelName(manufacturer: '', model: 'Pixel 8'), 'Pixel 8');
      expect(androidModelName(manufacturer: 'google', model: ' '), 'Google');
      expect(androidModelName(manufacturer: ' ', model: ''), isNull);
    });
  });
}
