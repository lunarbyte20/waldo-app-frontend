import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../models/employee.dart';

class ApiService {
  // Uses named constant from ApiConstants
  static const String baseUrl = ApiConstants.baseUrl;

  // --- Token Management ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
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
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.loginEndpoint}');
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
    final url = Uri.parse('$baseUrl${ApiConstants.logoutEndpoint}');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    );
    await clearToken();
    return _parseResponse(response);
  }

  /// GET /auth/me (Bearer token)
  static Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('$baseUrl${ApiConstants.meEndpoint}');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  /// Typed GET /auth/me
  static Future<Employee> getMeModel() async {
    final res = await getMe();
    final empData = res['employee'] ?? res['user'] ?? res;
    return Employee.fromJson(empData is Map<String, dynamic> ? empData : res);
  }

  // --- Attendance Endpoints ---

  /// GET /attendance/status (Bearer token)
  static Future<Map<String, dynamic>> getAttendanceStatus() async {
    final url = Uri.parse('$baseUrl${ApiConstants.attendanceStatusEndpoint}');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  /// Typed GET /attendance/status
  static Future<AttendanceStatus> getAttendanceStatusModel() async {
    final res = await getAttendanceStatus();
    return AttendanceStatus.fromJson(res);
  }

  /// POST /attendance/clock-in (Bearer token)
  static Future<Map<String, dynamic>> clockIn(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl${ApiConstants.clockInEndpoint}');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  /// POST /attendance/clock-out (Bearer token)
  static Future<Map<String, dynamic>> clockOut(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl${ApiConstants.clockOutEndpoint}');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  /// GET /attendance/history (Bearer token)
  static Future<Map<String, dynamic>> getAttendanceHistory({int page = 1}) async {
    final url = Uri.parse('$baseUrl${ApiConstants.attendanceHistoryEndpoint}?page=$page');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _parseResponse(response);
  }

  /// Typed GET /attendance/history list
  static Future<List<AttendanceRecord>> getAttendanceHistoryRecords({int page = 1}) async {
    final res = await getAttendanceHistory(page: page);
    final data = res['data'];
    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data.containsKey('data')) {
      items = data['data'] as List<dynamic>? ?? [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => AttendanceRecord.fromJson(json))
        .toList();
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
