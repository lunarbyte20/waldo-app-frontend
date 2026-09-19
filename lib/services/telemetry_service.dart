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
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );

          telemetry['latitude'] = position.latitude;
          telemetry['longitude'] = position.longitude;
          telemetry['gps_accuracy'] = position.accuracy;

          // Extract position.isMocked (Android native mock-location detection via
          // LocationManager.isFromMockProvider under the hood).
          // Note: position.isMocked is always false on iOS since Apple has no equivalent API.
          telemetry['is_mock_location'] = position.isMocked;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TelemetryService: Location fetch error: $e');
      }
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
