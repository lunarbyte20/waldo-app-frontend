import 'attendance_record.dart';

class AttendanceStatus {
  final AttendanceRecord? activeRecord;
  final int? assignedSiteId;
  final String? registeredDeviceId;
  final Map<String, dynamic>? siteAssignment;
  final List<dynamic> designatedSitePool;
  final List<dynamic> availableSchedules;
  final String? defaultSchedule;
  final Map<String, dynamic>? autoClosedNotice;
  final Map<String, dynamic> raw;

  AttendanceStatus({
    this.activeRecord,
    this.assignedSiteId,
    this.registeredDeviceId,
    this.siteAssignment,
    this.designatedSitePool = const [],
    this.availableSchedules = const [],
    this.defaultSchedule,
    this.autoClosedNotice,
    required this.raw,
  });

  bool get isClockedIn => activeRecord != null;

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    AttendanceRecord? record;
    if (json['active_record'] != null && json['active_record'] is Map<String, dynamic>) {
      record = AttendanceRecord.fromJson(json['active_record'] as Map<String, dynamic>);
    }

    int? siteId;
    if (json['site_assignment'] != null && json['site_assignment'] is Map) {
      siteId = int.tryParse(json['site_assignment']['site_id']?.toString() ?? '');
    } else if (json['assigned_site_id'] != null) {
      siteId = int.tryParse(json['assigned_site_id'].toString());
    }

    List<dynamic> scheds = json['schedules'] as List<dynamic>? ?? json['available_schedules'] as List<dynamic>? ?? [];

    return AttendanceStatus(
      activeRecord: record,
      assignedSiteId: siteId,
      registeredDeviceId: json['registered_device_id']?.toString(),
      siteAssignment: json['site_assignment'] is Map<String, dynamic> ? json['site_assignment'] as Map<String, dynamic> : null,
      designatedSitePool: json['designated_site_pool'] as List<dynamic>? ?? [],
      availableSchedules: scheds,
      defaultSchedule: json['default_schedule']?.toString(),
      autoClosedNotice: json['auto_closed_notice'] is Map<String, dynamic> ? json['auto_closed_notice'] as Map<String, dynamic> : null,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
