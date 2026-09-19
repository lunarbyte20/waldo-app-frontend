import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/waldo_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AttendanceRecord> _historyRecords = [];

  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedStatus;

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
      final dateFromStr = _dateFrom != null ? DateFormat('yyyy-MM-dd').format(_dateFrom!) : null;
      final dateToStr = _dateTo != null ? DateFormat('yyyy-MM-dd').format(_dateTo!) : null;

      final records = await ApiService.getAttendanceHistoryRecords(
        page: page,
        perPage: 30,
        dateFrom: dateFromStr,
        dateTo: dateToStr,
        status: _selectedStatus,
      );
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

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now().subtract(const Duration(days: 30))) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _selectedStatus = null;
    });
    _fetchHistory(page: 1);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTimeOnly(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _formatDuration(dynamic hoursWorked) {
    if (hoursWorked == null) return '-';
    final double hrs = (hoursWorked is num) ? hoursWorked.toDouble() : double.tryParse(hoursWorked.toString()) ?? 0.0;
    if (hrs <= 0) return '-';
    final int h = hrs.floor();
    final int m = ((hrs - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade700;
      case 'Pending':
        return Colors.amber.shade800;
      case 'Rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'attendance'),
      appBar: const WaldoAppBar(title: 'My Attendance Records'),
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(page: 1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header Banner
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Attendance Records',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your daily clock-in and clock-out logs, GPS validations, and statuses',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search & Filters Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search & Filters',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDate(context, true),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(_dateFrom == null ? 'Date From' : DateFormat('MMM dd, yyyy').format(_dateFrom!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDate(context, false),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(_dateTo == null ? 'Date To' : DateFormat('MMM dd, yyyy').format(_dateTo!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('All Statuses')),
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                              ],
                              onChanged: (val) => setState(() => _selectedStatus = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _fetchHistory(page: 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Apply'),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.clear_all_rounded),
                            tooltip: 'Reset Filters',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ErrorBanner(
                    message: _errorMessage!,
                    onRetry: () => _fetchHistory(page: 1),
                  ),
                ),
              ] else if (_historyRecords.isEmpty) ...[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No attendance records',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'There are no clock-logs matching your selected criteria.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _historyRecords.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _historyRecords[index];
                    final String siteName = item.siteName ?? 'Duty Site';
                    final String dateFormatted = _formatDate(item.date);
                    final String clockInTime = _formatTimeOnly(item.timeIn);
                    final String? clockOutTime = item.timeOut != null ? _formatTimeOnly(item.timeOut) : null;
                    final String durationFormatted = _formatDuration(item.hoursWorked);
                    final String dayCountStr = item.dayCount != null ? '${item.dayCount}d' : '-';
                    final String? reason = item.reason;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Site Name, Date, Status Badges
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        siteName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormatted,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Approval Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(item.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Entry Method Badge (GPS vs Manual)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.entryMethod == 'Manual' ? Colors.purple : Colors.blue,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.entryMethod,
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // GPS Status Badge (Valid vs Flagged)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.gpsStatus == 'Valid' ? Colors.green.shade700 : Colors.red.shade700,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.gpsStatus,
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Grid Info: Clock In, Clock Out, Duration, Day Count
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Clock In', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(clockInTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Clock Out', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      clockOutTime != null
                                          ? Text(clockOutTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'))
                                          : Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Active Shift',
                                                style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Duration', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(durationFormatted, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Day Count', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(dayCountStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Remarks / Exception Tags
                            if (reason != null && reason.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Remarks / Exceptions', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: reason.split('; ').map((tag) {
                                  final cleanTag = tag.trim();
                                  final isWarning = cleanTag.contains('Tardiness') || cleanTag.contains('Undertime');
                                  final isError = cleanTag.contains('GPS out of range') || cleanTag.contains('exceeds');
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isError
                                          ? Colors.red.shade100
                                          : (isWarning ? Colors.amber.shade100 : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isError
                                            ? Colors.red.shade300
                                            : (isWarning ? Colors.amber.shade300 : Colors.grey.shade400),
                                      ),
                                    ),
                                    child: Text(
                                      cleanTag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isError
                                            ? Colors.red.shade900
                                            : (isWarning ? Colors.amber.shade900 : Colors.black87),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
