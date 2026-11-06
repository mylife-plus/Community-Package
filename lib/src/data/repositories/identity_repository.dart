import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_error.dart';
import '../../core/identity/anon_id_source.dart';
import '../models/identity.dart';

/// The user's anonymous ID and their agreement to the rules. Owns the
/// identity stream.
class IdentityRepository {
  IdentityRepository(this._source, {Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const rulesAgreedKey = 'community_rules_agreed';

  final AnonIdSource _source;
  final Future<SharedPreferences> _prefs;
  final _controller = StreamController<Identity>.broadcast();

  /// The read in flight or done. A failed read is dropped, so the next
  /// [load] tries again.
  Future<Identity>? _identity;

  /// Every identity this repository resolves or changes to.
  Stream<Identity> get identityStream => _controller.stream;

  /// The saved identity, read once and shared by every caller.
  Future<Identity> load() {
    final running = _identity;
    if (running != null) return running;
    final read = _onDevice('read the anonymous ID', () async {
      return Identity(anonId: await _source.read(), rulesAgreed: await _rulesAgreed());
    });
    _identity = read;
    read.then(_publish, onError: (Object _) {
      if (identical(_identity, read)) _identity = null;
    });
    return read;
  }

  /// The ID to send as `X-Anon-Id`: null until the user agreed to the
  /// privacy notice, and null when it can't be read.
  Future<String?> requestAnonId() async {
    try {
      return (await load()).anonId;
    } on AppError {
      return null;
    }
  }

  /// The user agreed to the privacy notice: creates the ID, or returns the
  /// one that already exists.
  Future<Identity> agreeToPrivacy() async {
    final identity = await _onDevice('create the anonymous ID', () async {
      return Identity(anonId: await _source.create(), rulesAgreed: await _rulesAgreed());
    });
    return _set(identity);
  }

  /// The user agreed to the community rules.
  Future<Identity> agreeToRules() async {
    final current = await load();
    await _onDevice('save the rules agreement', () async {
      if (!await (await _prefs).setBool(rulesAgreedKey, true)) {
        throw const AppError(AppErrorType.storage, message: 'setBool returned false');
      }
    });
    return _set(current.copyWith(rulesAgreed: true));
  }

  void dispose() => _controller.close();

  Future<bool> _rulesAgreed() async => (await _prefs).getBool(rulesAgreedKey) ?? false;

  Identity _set(Identity identity) {
    _identity = Future.value(identity);
    _publish(identity);
    return identity;
  }

  // A read can finish after dispose, for example when init runs again.
  void _publish(Identity identity) {
    if (!_controller.isClosed) _controller.add(identity);
  }

  /// Runs Keychain or preferences work; every failure becomes an [AppError].
  static Future<T> _onDevice<T>(String what, Future<T> Function() run) async {
    try {
      return await run();
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      debugPrint('community identity: could not $what: $e');
      throw AppError(AppErrorType.storage, message: 'Could not $what');
    }
  }
}
