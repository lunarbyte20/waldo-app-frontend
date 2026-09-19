class ApiConstants {
  static const String baseUrl = 'http://192.168.1.3:8000/api/v1';

  // Endpoint paths
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  static const String attendanceStatusEndpoint = '/attendance/status';
  static const String clockInEndpoint = '/attendance/clock-in';
  static const String clockOutEndpoint = '/attendance/clock-out';
  static const String attendanceHistoryEndpoint = '/attendance/history';

  // Storage Keys
  static const String tokenKey = 'auth_token';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
}
