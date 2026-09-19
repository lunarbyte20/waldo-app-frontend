class AttendanceRecord {
  final dynamic id;
  final String? clockIn;
  final String? clockOut;
  final String gpsStatus;
  final String? reason;
  final dynamic hoursWorked;
  final dynamic dayCount;
  final dynamic siteId;
  final Map<String, dynamic> raw;

  AttendanceRecord({
    this.id,
    this.clockIn,
    this.clockOut,
    required this.gpsStatus,
    this.reason,
    this.hoursWorked,
    this.dayCount,
    this.siteId,
    required this.raw,
  });

  bool get isFlagged => gpsStatus.toLowerCase() == 'flagged';
  bool get isClockedIn => clockIn != null && clockOut == null;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      gpsStatus: json['gps_status']?.toString() ?? 'Valid',
      reason: json['reason']?.toString(),
      hoursWorked: json['hours_worked'],
      dayCount: json['day_count'],
      siteId: json['site_id'],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
