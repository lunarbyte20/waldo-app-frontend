import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Constant Base URL easy to change later
  static const String baseUrl = 'http://192.168.1.3:8000/api/v1';

  static const String _tokenKey = 'auth_token';

  // --- Token Management ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Authentication Endpoints ---

  /// POST /auth/login
  /// Request: { "email", "password", "device_id" }
  /// Response: { "token", "employee": {...} }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
      }),
    );

    final data = _parseResponse(response);
    if (data.containsKey('token') && data['token'] is String) {
      await saveToken(data['token']);
    }
    return data;
  }

  /// POST /auth/logout (Bearer token)
  static Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$baseUrl/auth/logout');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    );
    await clearToken();
    return _parseResponse(response);
  }

  /// GET /auth/me (Bearer token)
  static Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  // --- Attendance Endpoints ---

  /// GET /attendance/status (Bearer token)
  /// Response includes: active_record (null or object), assigned_site_id,
  /// geofence radius, available schedules
  static Future<Map<String, dynamic>> getAttendanceStatus() async {
    final url = Uri.parse('$baseUrl/attendance/status');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  /// POST /attendance/clock-in (Bearer token)
  /// Request: { latitude, longitude, gps_accuracy, is_mock_location,
  /// device_id, device_model, os_version, client_timestamp, photo_data (base64 JPEG),
  /// site_id, selected_schedule }
  /// Response: { status, gps_status ("Valid"/"Flagged"), attendance_status, reason }
  static Future<Map<String, dynamic>> clockIn(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/attendance/clock-in');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  /// POST /attendance/clock-out (Bearer token)
  /// Same request shape as clock-in, response also includes hours_worked and day_count
  static Future<Map<String, dynamic>> clockOut(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/attendance/clock-out');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  /// GET /attendance/history (Bearer token)
  /// Paginated list under "data"
  static Future<Map<String, dynamic>> getAttendanceHistory({int page = 1}) async {
    final url = Uri.parse('$baseUrl/attendance/history?page=$page');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  // --- Helper Response Parser ---
  static Map<String, dynamic> _parseResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } on FormatException {
      throw Exception(
        'Server returned non-JSON response (HTTP ${response.statusCode}). Please verify the backend URL.',
      );
    } catch (e) {
      throw Exception('Failed to parse server response (HTTP ${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return body;
      }
      return {'data': body};
    } else {
      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'HTTP ${response.statusCode}: Request failed';
      throw Exception(message);
    }
  }
}
