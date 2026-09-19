import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class TelemetryService {
  /// Collects location anti-spoofing telemetry and device information.
  /// Wraps all calls in error handling to keep fields gracefully optional
  /// so that failures (e.g. permission denied or missing device info) do not crash the app.
  static Future<Map<String, dynamic>> getTelemetryPayload() async {
    final Map<String, dynamic> telemetry = {
      'latitude': null,
      'longitude': null,
      'gps_accuracy': null,
      'is_mock_location': false,
      'device_id': null,
      'device_model': null,
      'os_version': null,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    // 1. Fetch Location Telemetry
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          try {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 10),
              ),
            );

            telemetry['latitude'] = position.latitude;
            telemetry['longitude'] = position.longitude;
            telemetry['gps_accuracy'] = position.accuracy;
            telemetry['is_mock_location'] = position.isMocked;
          } catch (currentPosErr) {
            if (kDebugMode) {
              print('TelemetryService: getCurrentPosition failed ($currentPosErr), trying getLastKnownPosition...');
            }
            Position? lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              telemetry['latitude'] = lastPosition.latitude;
              telemetry['longitude'] = lastPosition.longitude;
              telemetry['gps_accuracy'] = lastPosition.accuracy;
              telemetry['is_mock_location'] = lastPosition.isMocked;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TelemetryService: Location fetch error: $e');
      }
    }

    // Fallback for non-mobile platforms (Windows desktop / Web / debug environment without GPS hardware)
    if (telemetry['latitude'] == null && (!Platform.isAndroid && !Platform.isIOS)) {
      if (kDebugMode) {
        print('TelemetryService: Non-mobile platform detected without GPS hardware. Using desktop fallback coordinates.');
      }
      telemetry['latitude'] = 14.5995;
      telemetry['longitude'] = 120.9842;
      telemetry['gps_accuracy'] = 50.0;
    }

    // 2. Fetch Device Info
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        // Build fingerprint / device hardware ID
        telemetry['device_id'] = androidInfo.id;
        telemetry['device_model'] = '${androidInfo.manufacturer} ${androidInfo.model}';
        telemetry['os_version'] = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        // Stable iOS device identifier
        telemetry['device_id'] = iosInfo.identifierForVendor;
        telemetry['device_model'] = iosInfo.model;
        telemetry['os_version'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else {
        telemetry['device_id'] = 'UNKNOWN_PLATFORM';
        telemetry['device_model'] = defaultTargetPlatform.name;
        telemetry['os_version'] = 'Unknown OS';
      }
    } catch (e) {
      if (kDebugMode) {
        print('TelemetryService: Device info fetch error: $e');
      }
    }

    return telemetry;
  }
}
