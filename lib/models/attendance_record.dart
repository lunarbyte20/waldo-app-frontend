class AttendanceRecord {
  final dynamic id;
  final String? date;
  final String? timeIn;
  final String? timeOut;
  final String? siteName;
  final String entryMethod;
  final String gpsStatus;
  final String status;
  final String? reason;
  final dynamic hoursWorked;
  final dynamic dayCount;
  final int tardinessMinutes;
  final int undertimeMinutes;
  final String? matchedScheduleStart;
  final String? matchedScheduleEnd;
  final dynamic siteId;
  final Map<String, dynamic>? cutoffPeriod;
  final Map<String, dynamic> raw;

  AttendanceRecord({
    this.id,
    this.date,
    this.timeIn,
    this.timeOut,
    this.siteName,
    this.entryMethod = 'GPS',
    required this.gpsStatus,
    this.status = 'Approved',
    this.reason,
    this.hoursWorked,
    this.dayCount,
    this.tardinessMinutes = 0,
    this.undertimeMinutes = 0,
    this.matchedScheduleStart,
    this.matchedScheduleEnd,
    this.siteId,
    this.cutoffPeriod,
    required this.raw,
  });

  bool get isFlagged => gpsStatus.toLowerCase() == 'flagged';
  bool get isClockedIn => timeIn != null && timeOut == null;

  // Convenient legacy aliases
  String? get clockIn => timeIn;
  String? get clockOut => timeOut;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    String? inTime = json['time_in']?.toString() ?? json['clock_in']?.toString();
    String? outTime = json['time_out']?.toString() ?? json['clock_out']?.toString();
    
    String? site;
    if (json['site'] != null && json['site'] is Map) {
      site = json['site']['site_name']?.toString();
    } else if (json['site_name'] != null) {
      site = json['site_name']?.toString();
    }

    return AttendanceRecord(
      id: json['id'],
      date: json['date']?.toString(),
      timeIn: inTime,
      timeOut: outTime,
      siteName: site,
      entryMethod: json['entry_method']?.toString() ?? 'GPS',
      gpsStatus: json['gps_status']?.toString() ?? 'Valid',
      status: json['status']?.toString() ?? 'Approved',
      reason: json['reason']?.toString(),
      hoursWorked: json['hours_worked'],
      dayCount: json['day_count'],
      tardinessMinutes: int.tryParse(json['tardiness_minutes']?.toString() ?? '0') ?? 0,
      undertimeMinutes: int.tryParse(json['undertime_minutes']?.toString() ?? '0') ?? 0,
      matchedScheduleStart: json['matched_schedule_start']?.toString(),
      matchedScheduleEnd: json['matched_schedule_end']?.toString(),
      siteId: json['site_id'],
      cutoffPeriod: json['cutoff_period'] is Map<String, dynamic>
          ? json['cutoff_period'] as Map<String, dynamic>
          : null,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
