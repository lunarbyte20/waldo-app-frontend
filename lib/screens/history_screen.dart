import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _historyList = [];

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
      final res = await ApiService.getAttendanceHistory(page: page);
      if (!mounted) return;

      final data = res['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data.containsKey('data')) {
        items = data['data'] as List<dynamic>? ?? [];
      }

      setState(() {
        _historyList = items;
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _fetchHistory(page: 1),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _historyList.isEmpty
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
                        itemCount: _historyList.length,
                        itemBuilder: (context, index) {
                          final item = _historyList[index] as Map<String, dynamic>;
                          final String gpsStatus =
                              item['gps_status']?.toString() ?? 'Valid';
                          final bool isFlagged =
                              (gpsStatus.toLowerCase() == 'flagged');

                          final String clockIn = _formatDateTime(item['clock_in']?.toString());
                          final String? clockOut = item['clock_out'] != null
                              ? _formatDateTime(item['clock_out']?.toString())
                              : null;
                          final String? reason = item['reason']?.toString();

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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isFlagged
                                              ? Colors.amber.shade100
                                              : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isFlagged
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.check_circle_rounded,
                                              size: 16,
                                              color: isFlagged
                                                  ? Colors.amber.shade900
                                                  : Colors.green.shade900,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isFlagged ? 'FLAGGED LOCATION' : 'VALID / APPROVED',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isFlagged
                                                    ? Colors.amber.shade900
                                                    : Colors.green.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (item.containsKey('hours_worked') && item['hours_worked'] != null)
                                        Text(
                                          '${item['hours_worked']} hrs',
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
