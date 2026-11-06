import 'package:community_package/src/core/identity/anon_id_source.dart';
import 'package:flutter/services.dart';

/// An in-memory ID store that can be told to fail like the Keychain does.
class FakeAnonIdSource implements AnonIdSource {
  FakeAnonIdSource({this.id});

  String? id;
  bool failReads = false;
  bool failCreates = false;
  int reads = 0;
  int creates = 0;

  static const createdId = '0b5e7c2a-1111-4222-8333-444455556666';

  @override
  Future<String?> read() async {
    reads++;
    if (failReads) throw PlatformException(code: 'keychain', message: 'locked');
    return id;
  }

  @override
  Future<String> create() async {
    creates++;
    if (failCreates) throw PlatformException(code: 'keychain', message: 'locked');
    return id ??= createdId;
  }
}
