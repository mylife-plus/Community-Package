import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Disk tier of the 3-tier cache: JSON in SharedPreferences, with a TTL.
class PrefsCache {
  PrefsCache({Future<SharedPreferences>? prefs, DateTime Function()? now})
    : _prefs = prefs ?? SharedPreferences.getInstance(),
      _now = now ?? DateTime.now;

  /// Keeps the package's keys apart from the host app's.
  static const keyPrefix = 'community_cache_';

  final Future<SharedPreferences> _prefs;
  final DateTime Function() _now;

  /// The JSON stored under [key], or null when there is none, it is older
  /// than [ttl], or it can't be read. [ignoreTtl] returns stale data too,
  /// for when the network has failed and old data beats an error.
  Future<Object?> read(String key, {required Duration ttl, bool ignoreTtl = false}) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$keyPrefix$key');
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(entry['savedAt'] as int);
      if (!ignoreTtl && _now().difference(savedAt) > ttl) return null;
      return entry['data'];
    } catch (e) {
      debugPrint('community cache: dropping unreadable entry $key: $e');
      await prefs.remove('$keyPrefix$key');
      return null;
    }
  }

  Future<void> write(String key, Object? json) async {
    final prefs = await _prefs;
    final entry = jsonEncode({'savedAt': _now().millisecondsSinceEpoch, 'data': json});
    final saved = await prefs.setString('$keyPrefix$key', entry);
    if (!saved) debugPrint('community cache: write failed for $key');
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove('$keyPrefix$key');
  }
}
