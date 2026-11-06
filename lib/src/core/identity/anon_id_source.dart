import 'dart:convert';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_error.dart';

/// Where this platform keeps the user's anonymous ID.
///
/// [read] returns null until the user agreed to the privacy notice, so no
/// ID exists or leaves the phone before that.
abstract interface class AnonIdSource {
  /// iOS keeps the ID in the Keychain, Android derives it from ANDROID_ID,
  /// and every other platform keeps it in SharedPreferences.
  factory AnonIdSource.forPlatform() {
    if (kIsWeb) return PrefsAnonIdSource();
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => KeychainAnonIdSource(),
      TargetPlatform.android => AndroidAnonIdSource(),
      _ => PrefsAnonIdSource(),
    };
  }

  /// The ID, or null when the user has not agreed yet.
  Future<String?> read();

  /// Called once the user agreed. Returns the existing ID when there is one,
  /// and never replaces it.
  Future<String> create();
}

/// iOS: a random UUID in the Keychain. Keychain items survive deleting and
/// reinstalling the app on current iOS versions (not guaranteed by Apple).
class KeychainAnonIdSource implements AnonIdSource {
  KeychainAnonIdSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _options);

  static const key = 'community_anon_id';

  // Readable after the first unlock following a restart. Not the
  // "this device" variant, so an encrypted backup carries the ID to a new phone.
  static const _options = IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final value = await _storage.read(key: key);
    return isValidAnonId(value) ? value : null;
  }

  @override
  Future<String> create() async {
    final existing = await read();
    if (existing != null) return existing;
    final id = randomUuid();
    await _storage.write(key: key, value: id);
    return id;
  }
}

/// Android: a UUID derived from ANDROID_ID, so the same ID comes back after a
/// reinstall. ANDROID_ID itself never leaves the phone, only its hash.
///
/// The ID can be derived at any time, so a saved "agreed" flag decides
/// whether it exists yet.
class AndroidAnonIdSource implements AnonIdSource {
  AndroidAnonIdSource({Future<String?> Function()? androidId, Future<SharedPreferences>? prefs})
    : _androidId = androidId ?? const AndroidId().getId,
      _prefs = prefs ?? SharedPreferences.getInstance(),
      _fallback = PrefsAnonIdSource(prefs: prefs);

  static const agreedKey = 'community_privacy_agreed';

  // Never change this: the ID of every Android user depends on it. It keeps
  // the hash apart from any other app that hashes ANDROID_ID.
  static const _hashPrefix = 'community_package:';

  final Future<String?> Function() _androidId;
  final Future<SharedPreferences> _prefs;

  /// For the rare phone without an ANDROID_ID.
  final PrefsAnonIdSource _fallback;

  @override
  Future<String?> read() async {
    final prefs = await _prefs;
    if (prefs.getBool(agreedKey) != true) return null;
    return await _derive() ?? await _fallback.read();
  }

  @override
  Future<String> create() async {
    final id = await _derive() ?? await _fallback.create();
    final prefs = await _prefs;
    if (!await prefs.setBool(agreedKey, true)) {
      throw const AppError(AppErrorType.storage, message: 'Could not save the privacy agreement');
    }
    return id;
  }

  Future<String?> _derive() async {
    final raw = await _androidId();
    if (raw == null || raw.isEmpty) return null;
    return sha256Uuid('$_hashPrefix$raw');
  }
}

/// Other platforms, and Android phones without an ANDROID_ID: a random UUID
/// in SharedPreferences. It is lost when the app is deleted.
class PrefsAnonIdSource implements AnonIdSource {
  PrefsAnonIdSource({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const key = 'community_anon_id';

  final Future<SharedPreferences> _prefs;

  @override
  Future<String?> read() async {
    final value = (await _prefs).getString(key);
    return isValidAnonId(value) ? value : null;
  }

  @override
  Future<String> create() async {
    final existing = await read();
    if (existing != null) return existing;
    final id = randomUuid();
    if (!await (await _prefs).setString(key, id)) {
      throw const AppError(AppErrorType.storage, message: 'Could not save the anonymous ID');
    }
    return id;
  }
}

final _uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Whether [value] has the lowercase UUID shape the backend accepts.
bool isValidAnonId(String? value) => value != null && _uuidPattern.hasMatch(value);

/// A random UUID, version 4 (RFC 9562, section 5.4).
String randomUuid([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _format(bytes);
}

/// A name-based UUID from SHA-256, version 8, as in RFC 9562, appendix B.2:
/// the first 16 bytes of the hash with the version and variant bits set.
String sha256Uuid(String name) {
  final bytes = sha256.convert(utf8.encode(name)).bytes.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x80;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _format(bytes);
}

String _format(List<int> bytes) {
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
