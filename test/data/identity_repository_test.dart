import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/data/models/identity.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';

Matcher _storageError() =>
    throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.storage));

void main() {
  late FakeAnonIdSource source;
  late IdentityRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    source = FakeAnonIdSource();
    repository = IdentityRepository(source);
  });

  tearDown(() => repository.dispose());

  test('reads once and shares the result', () async {
    final results = await Future.wait([repository.load(), repository.load()]);

    expect(results, everyElement(const Identity()));
    expect(source.reads, 1);
    await repository.load();
    expect(source.reads, 1);
  });

  test('publishes what it reads', () async {
    source.id = FakeAnonIdSource.createdId;
    final published = repository.identityStream.first;

    await repository.load();

    expect(await published, const Identity(anonId: FakeAnonIdSource.createdId));
  });

  test('sends no ID until the user agreed to the privacy notice', () async {
    expect(await repository.requestAnonId(), isNull);

    final identity = await repository.agreeToPrivacy();

    expect(identity.anonId, FakeAnonIdSource.createdId);
    expect(identity.agreedToPrivacy, isTrue);
    expect(await repository.requestAnonId(), FakeAnonIdSource.createdId);
  });

  test('agreeing to the privacy notice publishes the new identity', () async {
    final published = repository.identityStream.first;

    await repository.agreeToPrivacy();

    expect((await published).anonId, FakeAnonIdSource.createdId);
  });

  test('saves the rules agreement', () async {
    await repository.agreeToPrivacy();
    final identity = await repository.agreeToRules();

    expect(identity.rulesAgreed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(IdentityRepository.rulesAgreedKey), isTrue);

    final restarted = IdentityRepository(source);
    expect(await restarted.load(), identity);
    restarted.dispose();
  });

  test('a failed read becomes an AppError and is tried again next time', () async {
    source.failReads = true;

    await expectLater(repository.load(), _storageError());
    expect(await repository.requestAnonId(), isNull);

    source
      ..failReads = false
      ..id = FakeAnonIdSource.createdId;
    expect(await repository.requestAnonId(), FakeAnonIdSource.createdId);
  });

  test('a failed create becomes an AppError and leaves no ID', () async {
    source.failCreates = true;

    await expectLater(repository.agreeToPrivacy(), _storageError());
    expect(await repository.requestAnonId(), isNull);
  });
}
