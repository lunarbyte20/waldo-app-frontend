import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/telemetry_service.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  bool _isLoadingStatus = true;
  bool _isActionInProgress = false;
  Map<String, dynamic>? _activeRecord;
  int? _assignedSiteId;
  List<dynamic> _availableSchedules = [];
  dynamic _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStatus();
  }

  Future<void> _fetchAttendanceStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final res = await ApiService.getAttendanceStatus();
      if (!mounted) return;
      setState(() {
        _activeRecord = res['active_record'] as Map<String, dynamic>?;
        _assignedSiteId = res['assigned_site_id'] as int?;
        _availableSchedules = res['available_schedules'] as List<dynamic>? ?? [];
        if (_availableSchedules.isNotEmpty) {
          _selectedSchedule = _availableSchedules.first;
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
    // 1. Prompt for Camera Selfie (Camera ONLY - fraud prevention)
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

      // 4. Build complete request payload
      final payload = <String, dynamic>{
        ...telemetry,
        'photo_data': photoData,
        'site_id': _assignedSiteId,
        'selected_schedule': _selectedSchedule,
      };

      final bool isClockingIn = (_activeRecord == null);
      final Map<String, dynamic> response = isClockingIn
          ? await ApiService.clockIn(payload)
          : await ApiService.clockOut(payload);

      if (!mounted) return;

      // 5. Handle response & GPS flagged notices
      final String gpsStatus = response['gps_status']?.toString() ?? 'Valid';
      final String? reason = response['reason']?.toString();

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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of WALDO Guard App?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isClockedIn = (_activeRecord != null);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        title: const Text('WALDO Guard Clock'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Attendance History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          'Clocked in since: ${_activeRecord!['clock_in'] ?? 'Recently'}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Assigned Site ID: ${_assignedSiteId ?? 'Default'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

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
                  height: 140,
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
                                size: 48,
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

              const SizedBox(height: 32),

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
                    Expanded(
                      child: Text(
                        'Location & camera selfie will be recorded for anti-spoofing compliance.',
                        style: theme.textTheme.bodySmall,
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
