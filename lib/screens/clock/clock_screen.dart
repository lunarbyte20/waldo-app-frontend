import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../models/attendance_record.dart';
import '../../services/api_service.dart';
import '../../services/telemetry_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/waldo_app_bar.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  bool _isLoadingStatus = true;
  bool _isActionInProgress = false;
  AttendanceRecord? _activeRecord;
  int? _assignedSiteId;
  String? _assignedSiteName;
  List<dynamic> _designatedSitePool = [];
  List<dynamic> _availableSchedules = [];
  dynamic _selectedSchedule;
  int? _selectedSiteId;
  Map<String, dynamic>? _autoClosedNotice;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStatus();
  }

  Future<void> _fetchAttendanceStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final statusModel = await ApiService.getAttendanceStatusModel();
      if (!mounted) return;
      
      final raw = statusModel.raw;
      final siteAssign = raw['site_assignment'] as Map<String, dynamic>?;
      final pool = statusModel.designatedSitePool;
      final defaultSched = statusModel.defaultSchedule;
      final autoNotice = statusModel.autoClosedNotice;

      setState(() {
        _activeRecord = statusModel.activeRecord;
        _assignedSiteId = statusModel.assignedSiteId;
        _assignedSiteName = siteAssign?['site']?['site_name']?.toString() ?? (_activeRecord?.siteName);
        _designatedSitePool = pool;
        _availableSchedules = statusModel.availableSchedules;
        _autoClosedNotice = autoNotice;

        if (defaultSched != null && defaultSched.isNotEmpty) {
          _selectedSchedule = defaultSched;
        } else if (_availableSchedules.isNotEmpty) {
          final first = _availableSchedules.first;
          _selectedSchedule = (first is List && first.length >= 2) ? '${first[0]}-${first[1]}' : first.toString();
        }

        if (_assignedSiteId != null) {
          _selectedSiteId = _assignedSiteId;
        } else if (_designatedSitePool.isNotEmpty) {
          _selectedSiteId = int.tryParse(_designatedSitePool.first['id'].toString());
        }

        _isLoadingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStatus = false);
      _showSnackBar('Failed to load attendance status: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> _handleClockAction() async {
    // 1. Prompt for Camera Selfie (Camera ONLY - fraud prevention requirement)
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera, // STRICT REQUIREMENT: Camera ONLY, no gallery
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 75,
    );

    if (photo == null) {
      _showSnackBar('Selfie verification is required to proceed.');
      return;
    }

    setState(() => _isActionInProgress = true);

    try {
      // 2. Read image bytes and convert to base64 JPEG string
      final bytes = await photo.readAsBytes();
      final String photoData = base64Encode(bytes);

      // 3. Get location & device telemetry
      final telemetry = await TelemetryService.getTelemetryPayload();

      if (telemetry['latitude'] == null || telemetry['longitude'] == null) {
        if (!mounted) return;
        _showSnackBar('GPS location required. Please ensure location services are enabled on your device and try again.');
        return;
      }

      // 4. Build complete request payload
      final payload = <String, dynamic>{
        ...telemetry,
        'photo_data': photoData,
        'site_id': _selectedSiteId ?? _assignedSiteId,
        'selected_schedule': _selectedSchedule,
      };

      final bool isClockingIn = (_activeRecord == null);
      final Map<String, dynamic> response = isClockingIn
          ? await ApiService.clockIn(payload)
          : await ApiService.clockOut(payload);

      if (!mounted) return;

      // 5. Handle response & GPS flagged notices
      final String gpsStatus = response['gps_status']?.toString() ?? response['record']?['gps_status']?.toString() ?? 'Valid';
      final String? reason = response['reason']?.toString() ?? response['record']?['reason']?.toString();

      if (gpsStatus == 'Flagged') {
        _showPendingReviewNotice(
          action: isClockingIn ? 'Clock In' : 'Clock Out',
          reason: reason ?? 'Location flagged for manual supervisor review.',
        );
      } else {
        _showSnackBar(
          isClockingIn
              ? 'Clocked In Successfully!'
              : 'Clocked Out Successfully!',
          isSuccess: true,
        );
      }

      // Refresh status after successful action
      await _fetchAttendanceStatus();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Submission error: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _showPendingReviewNotice({required String action, required String reason}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
        title: Text('$action Recorded (Pending Review)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your submission was successfully recorded, but flagged by location anti-spoofing verification.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                'Reason: $reason',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A supervisor will review your location details.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understand'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatScheduleDisplay(dynamic sched) {
    if (sched == null) return '08:00-20:00';
    if (sched is List && sched.length >= 2) {
      return '${sched[0]} - ${sched[1]}';
    }
    return sched.toString();
  }

  String _formatScheduleValue(dynamic sched) {
    if (sched == null) return '08:00-20:00';
    if (sched is List && sched.length >= 2) {
      return '${sched[0]}-${sched[1]}';
    }
    return sched.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isClockedIn = (_activeRecord != null);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'clock'),
      appBar: const WaldoAppBar(title: 'WALDO Guard Clock'),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Auto-Closed Session Notice Banner (if any)
              if (_autoClosedNotice != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Notice: Your previous session was automatically closed after exceeding 14 hours and flagged for review.',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current Date & Time Banner
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Shift Time: ${DateFormat('hh:mm a').format(DateTime.now())}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status Indicator Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isClockedIn
                              ? Colors.green.shade100
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isClockedIn ? Colors.green : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isClockedIn ? 'ON DUTY' : 'OFF DUTY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isClockedIn
                                    ? Colors.green.shade900
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isClockedIn ? 'Currently Clocked In' : 'Ready to Start Shift',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (isClockedIn && _activeRecord != null) ...[
                        Text(
                          'Clocked in since: ${_activeRecord!.timeIn ?? 'Recently'}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_activeRecord!.siteName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Duty Site: ${_activeRecord!.siteName}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'Duty Site: ${_assignedSiteName ?? 'Assigned Duty Site'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Shift Schedule & Duty Site Selection (Only when Clocking In)
              if (!isClockedIn) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift Schedule & Duty Site',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Shift Schedule Dropdown
                        if (_availableSchedules.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSchedule != null ? _formatScheduleValue(_selectedSchedule) : null,
                            decoration: const InputDecoration(
                              labelText: 'Select Shift Schedule',
                              prefixIcon: Icon(Icons.access_time_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _availableSchedules.map((s) {
                              final val = _formatScheduleValue(s);
                              final disp = _formatScheduleDisplay(s);
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(disp, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSchedule = val),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Designated Site Pool Dropdown (If Reliever/Pool Guard)
                        if (_designatedSitePool.isNotEmpty) ...[
                          DropdownButtonFormField<int>(
                            initialValue: _selectedSiteId,
                            decoration: const InputDecoration(
                              labelText: 'Select Duty Site (Site Pool)',
                              prefixIcon: Icon(Icons.location_on_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _designatedSitePool.map((site) {
                              final id = int.tryParse(site['id'].toString()) ?? 0;
                              final name = site['site_name']?.toString() ?? 'Site #$id';
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSiteId = val),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Big Primary Action Button (Clock In / Clock Out)
              if (_isLoadingStatus) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              ] else ...[
                SizedBox(
                  height: 120,
                  child: ElevatedButton(
                    onPressed: _isActionInProgress ? null : _handleClockAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClockedIn ? Colors.red.shade700 : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isActionInProgress
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text('Verifying GPS & Selfie...'),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isClockedIn
                                    ? Icons.timer_off_rounded
                                    : Icons.timer_rounded,
                                size: 44,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Security & Telemetry Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        AppConstants.antiSpoofingNotice,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
