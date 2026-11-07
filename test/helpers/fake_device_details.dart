import 'package:community_package/src/core/identity/device_details.dart';

/// Device details without the plugins. [gate] holds the read back.
class FakeDeviceDetailsSource implements DeviceDetailsSource {
  FakeDeviceDetailsSource({this.details = sample, this.gate});

  static const sample = DeviceDetails(osVersion: 'iOS 18.1', appVersion: '3.2.0', deviceModel: 'iPhone 15 Pro');

  final DeviceDetails details;
  final Future<void>? gate;
  int reads = 0;

  @override
  Future<DeviceDetails> read() async {
    reads++;
    await gate;
    return details;
  }
}
