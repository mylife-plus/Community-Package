import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'ios_device_names.dart';

/// The phone details a Problem carries. A detail that could not be read is
/// null.
@immutable
class DeviceDetails {
  const DeviceDetails({this.osVersion, this.appVersion, this.deviceModel});

  /// For example `iOS 18.1` or `Android 15`.
  final String? osVersion;

  /// The host app's version, for example `3.2.0`.
  final String? appVersion;

  /// For example `iPhone 15 Pro` or `Google Pixel 8`.
  final String? deviceModel;

  static const unknown = DeviceDetails();

  @override
  bool operator ==(Object other) =>
      other is DeviceDetails &&
      other.osVersion == osVersion &&
      other.appVersion == appVersion &&
      other.deviceModel == deviceModel;

  @override
  int get hashCode => Object.hash(osVersion, appVersion, deviceModel);
}

/// Reads [DeviceDetails] from the phone.
abstract interface class DeviceDetailsSource {
  factory DeviceDetailsSource.forPlatform() = _PluginDeviceDetailsSource;

  /// Never throws: details that cannot be read are null.
  Future<DeviceDetails> read();
}

/// Reads once, through device_info_plus and package_info_plus, and keeps
/// the result: none of it changes while the app runs.
class _PluginDeviceDetailsSource implements DeviceDetailsSource {
  Future<DeviceDetails>? _details;

  @override
  Future<DeviceDetails> read() => _details ??= _read();

  Future<DeviceDetails> _read() async {
    final (os, model) = await _system();
    return DeviceDetails(osVersion: os, appVersion: await _appVersion(), deviceModel: model);
  }

  Future<String?> _appVersion() async {
    try {
      final version = (await PackageInfo.fromPlatform()).version.trim();
      return version.isEmpty ? null : version;
    } catch (e) {
      debugPrint('community device details: app version: $e');
      return null;
    }
  }

  Future<(String?, String?)> _system() async {
    if (kIsWeb) return (null, null);
    try {
      final plugin = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return (
            '${info.systemName} ${info.systemVersion}',
            iosModelName(modelName: info.modelName, machine: info.utsname.machine, model: info.model),
          );
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return (
            'Android ${info.version.release}',
            androidModelName(manufacturer: info.manufacturer, model: info.model),
          );
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          return (null, null);
      }
    } catch (e) {
      debugPrint('community device details: system: $e');
      return (null, null);
    }
  }
}

/// The iOS model for people, for example `iPhone 18 Pro`.
///
/// [machine] is the device identifier (`iPhone19,2`; on a simulator, the
/// simulated model's). [iosDeviceNames] comes first, since device_info_plus
/// 11 names only models up to 2025 and returns `Unknown device` for newer
/// ones (DeviceIdentifiers.m); 12 and later need a newer Android Gradle
/// Plugin than the apps use. Then [modelName], then the identifier itself,
/// then [model] (`iPhone`).
@visibleForTesting
String? iosModelName({required String modelName, required String machine, required String model}) {
  final known = iosDeviceNames[machine];
  if (known != null) return known;
  if (modelName.isNotEmpty && modelName != 'Unknown device') return modelName;
  if (machine.startsWith('iP')) return machine;
  return model.isEmpty ? null : model;
}

/// The Android model for people: the maker, then the model, without the
/// maker twice. For example `Google Pixel 8`, `Samsung SM-S918B`.
@visibleForTesting
String? androidModelName({required String manufacturer, required String model}) {
  final maker = manufacturer.trim();
  final name = model.trim();
  if (maker.isEmpty) return name.isEmpty ? null : name;
  if (name.isEmpty) return _capitalized(maker);
  if (name.toLowerCase().startsWith(maker.toLowerCase())) return name;
  return '${_capitalized(maker)} $name';
}

String _capitalized(String word) => word[0].toUpperCase() + word.substring(1);
