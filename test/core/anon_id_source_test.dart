import 'dart:math';

import 'package:community_package/src/core/identity/anon_id_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('UUID helpers', () {
    test('randomUuid is a version 4 UUID the backend accepts', () {
      final ids = {for (var i = 0; i < 50; i++) randomUuid()};

      expect(ids, hasLength(50));
      for (final id in ids) {
        expect(isValidAnonId(id), isTrue, reason: id);
        expect(id[14], '4', reason: id);
        expect('89ab'.contains(id[19]), isTrue, reason: id);
      }
    });

    test('randomUuid sets the version bits on any random bytes', () {
      expect(randomUuid(_AllOnes()), 'ffffffff-ffff-4fff-bfff-ffffffffffff');
    });

    test('sha256Uuid is stable, version 8 and accepted by the backend', () {
      final a = sha256Uuid('community_package:abc');

      expect(sha256Uuid('community_package:abc'), a);
      expect(sha256Uuid('community_package:abd'), isNot(a));
      expect(isValidAnonId(a), isTrue);
      expect(a[14], '8');
      expect('89ab'.contains(a[19]), isTrue);
    });

    test('isValidAnonId rejects anything that is not a lowercase UUID', () {
      expect(isValidAnonId(null), isFalse);
      expect(isValidAnonId(''), isFalse);
      expect(isValidAnonId('not-a-uuid'), isFalse);
      expect(isValidAnonId('0B5E7C2A-1111-4222-8333-444455556666'), isFalse);
    });
  });

  group('AndroidAnonIdSource', () {
    const androidId = '9774d56d682e549c';
    final expected = sha256Uuid('community_package:$androidId');

    test('has no ID and never reads ANDROID_ID before the user agreed', () async {
      var calls = 0;
      final source = AndroidAnonIdSource(androidId: () async {
        calls++;
        return androidId;
      });

      expect(await source.read(), isNull);
      expect(calls, 0);
    });

    test('derives the ID from the ANDROID_ID hash once the user agreed', () async {
      final source = AndroidAnonIdSource(androidId: () async => androidId);

      expect(await source.create(), expected);
      expect(await source.read(), expected);
      expect(expected.contains(androidId), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AndroidAnonIdSource.agreedKey), isTrue);
    });

    test('a reinstall that kept nothing asks again and gets the same ID', () async {
      await AndroidAnonIdSource(androidId: () async => androidId).create();

      SharedPreferences.setMockInitialValues({});
      final reinstalled = AndroidAnonIdSource(androidId: () async => androidId);

      expect(await reinstalled.read(), isNull);
      expect(await reinstalled.create(), expected);
    });

    test('without an ANDROID_ID it keeps a random ID instead', () async {
      final source = AndroidAnonIdSource(androidId: () async => null);

      expect(await source.read(), isNull);
      final id = await source.create();

      expect(isValidAnonId(id), isTrue);
      expect(await source.read(), id);
      expect(await source.create(), id);
    });
  });

  group('KeychainAnonIdSource', () {
    test('has no ID until create, then keeps the same one', () async {
      final source = KeychainAnonIdSource();

      expect(await source.read(), isNull);
      final id = await source.create();

      expect(isValidAnonId(id), isTrue);
      expect(await source.read(), id);
      expect(await KeychainAnonIdSource().create(), id);
    });

    test('a damaged value counts as no ID and is replaced', () async {
      FlutterSecureStorage.setMockInitialValues({KeychainAnonIdSource.key: 'garbage'});
      final source = KeychainAnonIdSource();

      expect(await source.read(), isNull);
      final id = await source.create();
      expect(isValidAnonId(id), isTrue);
      expect(await source.read(), id);
    });
  });

  group('PrefsAnonIdSource', () {
    test('has no ID until create, then keeps the same one', () async {
      final source = PrefsAnonIdSource();

      expect(await source.read(), isNull);
      final id = await source.create();

      expect(await source.read(), id);
      expect(await PrefsAnonIdSource().create(), id);
    });
  });
}

class _AllOnes implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 1;
}
