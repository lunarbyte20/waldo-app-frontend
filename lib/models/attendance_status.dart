import 'attendance_record.dart';

class AttendanceStatus {
  final AttendanceRecord? activeRecord;
  final int? assignedSiteId;
  final dynamic geofenceRadius;
  final List<dynamic> availableSchedules;
  final Map<String, dynamic> raw;

  AttendanceStatus({
    this.activeRecord,
    this.assignedSiteId,
    this.geofenceRadius,
    this.availableSchedules = const [],
    required this.raw,
  });

  bool get isClockedIn => activeRecord != null;

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    AttendanceRecord? record;
    if (json['active_record'] != null && json['active_record'] is Map<String, dynamic>) {
      record = AttendanceRecord.fromJson(json['active_record'] as Map<String, dynamic>);
    }

    int? siteId;
    if (json['assigned_site_id'] != null) {
      siteId = int.tryParse(json['assigned_site_id'].toString());
    }

    return AttendanceStatus(
      activeRecord: record,
      assignedSiteId: siteId,
      geofenceRadius: json['geofence_radius'],
      availableSchedules: json['available_schedules'] as List<dynamic>? ?? [],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
