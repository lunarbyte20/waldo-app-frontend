import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../services/api_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AttendanceRecord> _historyRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await ApiService.getAttendanceHistoryRecords(page: page);
      if (!mounted) return;

      setState(() {
        _historyRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(page: 1),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ErrorBanner(
                        message: _errorMessage!,
                        onRetry: () => _fetchHistory(page: 1),
                      ),
                    ),
                  )
                : _historyRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded,
                                size: 56, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance history recorded yet.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _historyRecords.length,
                        itemBuilder: (context, index) {
                          final item = _historyRecords[index];
                          final bool isFlagged = item.isFlagged;

                          final String clockIn = _formatDateTime(item.clockIn);
                          final String? clockOut = item.clockOut != null
                              ? _formatDateTime(item.clockOut)
                              : null;
                          final String? reason = item.reason;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: isFlagged
                                  ? BorderSide(color: Colors.amber.shade400, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Status Badge (Approved vs Flagged)
                                      StatusBadge(isFlagged: isFlagged),

                                      if (item.hoursWorked != null)
                                        Text(
                                          '${item.hoursWorked} hrs',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Clock In info
                                  Row(
                                    children: [
                                      const Icon(Icons.login_rounded,
                                          size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Clock In: ',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          clockIn,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Clock Out info
                                  Row(
                                    children: [
                                      const Icon(Icons.logout_rounded,
                                          size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Clock Out: ',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          clockOut ?? 'Still Active (On Duty)',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: clockOut == null
                                                ? theme.colorScheme.primary
                                                : null,
                                            fontWeight: clockOut == null
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (isFlagged && reason != null && reason.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              size: 16, color: Colors.amber.shade900),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Reason: $reason',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
