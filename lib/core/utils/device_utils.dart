import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  DeviceUtils._();

  static String? _cachedDeviceId;
  static String? _cachedDeviceModel;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor ?? 'unknown-ios';
      }
    } catch (_) {}
    _cachedDeviceId ??= 'unknown-device';
    return _cachedDeviceId!;
  }

  static Future<String> getDeviceModel() async {
    if (_cachedDeviceModel != null) return _cachedDeviceModel!;
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedDeviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceModel = iosInfo.utsname.machine;
      }
    } catch (_) {}
    _cachedDeviceModel ??= 'unknown';
    return _cachedDeviceModel!;
  }
}
