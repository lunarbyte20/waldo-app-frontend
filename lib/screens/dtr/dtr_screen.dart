import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class CutoffPeriodItem {
  final dynamic id;
  final String startDate;
  final String endDate;
  final String status;
  final bool isPublished;
  final List<AttendanceRecord> records;

  CutoffPeriodItem({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isPublished,
    required this.records,
  });

  String get formattedRange {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final startFmt = DateFormat('MMM dd').format(start);
      final endFmt = DateFormat('MMM dd, yyyy').format(end);
      return '$startFmt - $endFmt';
    } catch (_) {
      return '$startDate - $endDate';
    }
  }
}

class DtrScreen extends StatefulWidget {
  const DtrScreen({super.key});

  @override
  State<DtrScreen> createState() => _DtrScreenState();
}

class _DtrScreenState extends State<DtrScreen> {
  bool _isLoading = true;
  List<AttendanceRecord> _records = [];
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDtrData();
  }

  Future<void> _fetchDtrData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateFromStr = _dateFrom != null ? DateFormat('yyyy-MM-dd').format(_dateFrom!) : null;
      final dateToStr = _dateTo != null ? DateFormat('yyyy-MM-dd').format(_dateTo!) : null;

      final records = await ApiService.getAttendanceHistoryRecords(
        page: 1,
        perPage: 50,
        dateFrom: dateFromStr,
        dateTo: dateToStr,
        status: _selectedStatus,
      );

      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now().subtract(const Duration(days: 15))) : (_dateTo ?? DateTime.now()),
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
    _fetchDtrData();
  }

  List<CutoffPeriodItem> get _cutoffPeriodItems {
    if (_records.isEmpty) {
      // Default sample fallback cutoff period matching active date range when empty
      final now = DateTime.now();
      final start = DateFormat('yyyy-MM-16').format(now);
      final end = DateFormat('yyyy-MM-30').format(now);
      return [
        CutoffPeriodItem(
          id: 1,
          startDate: start,
          endDate: end,
          status: 'Open',
          isPublished: true,
          records: [],
        )
      ];
    }

    final Map<String, List<AttendanceRecord>> grouped = {};
    final Map<String, Map<String, dynamic>> metadata = {};

    for (var r in _records) {
      if (r.status == 'Rejected') continue;

      final cutoffMap = r.cutoffPeriod;
      String key;
      String startDate;
      String endDate;
      String status = 'Open';
      bool isPublished = true;

      if (cutoffMap != null && cutoffMap['id'] != null) {
        key = cutoffMap['id'].toString();
        startDate = cutoffMap['start_date']?.toString() ?? r.date ?? '2026-09-16';
        endDate = cutoffMap['end_date']?.toString() ?? r.date ?? '2026-09-30';
        status = cutoffMap['status']?.toString() ?? 'Open';
        final pubVal = cutoffMap['dtr_published'];
        isPublished = pubVal == true || pubVal == 1 || pubVal == '1' || pubVal == null;
      } else {
        if (r.date != null) {
          try {
            final dt = DateTime.parse(r.date!);
            if (dt.day <= 15) {
              startDate = DateFormat('yyyy-MM-01').format(dt);
              endDate = DateFormat('yyyy-MM-15').format(dt);
            } else {
              startDate = DateFormat('yyyy-MM-16').format(dt);
              final lastDay = DateTime(dt.year, dt.month + 1, 0);
              endDate = DateFormat('yyyy-MM-dd').format(lastDay);
            }
          } catch (_) {
            startDate = '2026-09-16';
            endDate = '2026-09-30';
          }
          key = '$startDate-$endDate';
        } else {
          key = 'current';
          startDate = '2026-09-16';
          endDate = '2026-09-30';
        }
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
        metadata[key] = {
          'id': cutoffMap?['id'] ?? key,
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
          'is_published': isPublished,
        };
      }
      grouped[key]!.add(r);
    }

    return metadata.entries.map((e) {
      final meta = e.value;
      return CutoffPeriodItem(
        id: meta['id'],
        startDate: meta['start_date'],
        endDate: meta['end_date'],
        status: meta['status'],
        isPublished: meta['is_published'],
        records: grouped[e.key] ?? [],
      );
    }).toList();
  }

  void _viewPdfDetails(CutoffPeriodItem item) {
    final pdfUrl = '${ApiService.baseUrl}/attendance/dtr/${item.id}?action=view';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Finalized DTR Preview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        item.formattedRange,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cutoff Period Status:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text(item.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Records:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text('${item.records.length} logs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daily Time Record Logs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),
                  if (item.records.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No attendance logs recorded for this cutoff period.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...item.records.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              r.date ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'In: ${r.timeIn != null ? r.timeIn!.split('T').last.substring(0, 5) : '-'} | Out: ${r.timeOut != null ? r.timeOut!.split('T').last.substring(0, 5) : '-'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: r.status == 'Approved' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: r.status == 'Approved' ? const Color(0xFF166534) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showUrlDialog('View PDF Document', pdfUrl);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    label: const Text('Open PDF Web View Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF214070),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadPdfReport(CutoffPeriodItem item) {
    final pdfUrl = '${ApiService.baseUrl}/attendance/dtr/${item.id}?action=download';
    _showUrlDialog('Download DTR PDF', pdfUrl);
  }

  void _showUrlDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF214070)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your DTR PDF document URL has been generated:',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading DTR PDF Report...'),
                  backgroundColor: Color(0xFF214070),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF214070),
              foregroundColor: Colors.white,
            ),
            child: const Text('Download Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cutoffItems = _cutoffPeriodItems;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'dtr'),
      appBar: AppBar(
        title: const Text('My DTR Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDtrData,
            tooltip: 'Refresh DTR',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDtrData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row matching exact UI design
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF1E293B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My DTR Reports',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'View and download your finalized Daily Time Records',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFCBD5E1), height: 28, thickness: 1),
              const SizedBox(height: 4),

              // Filter Controls Card matching exact UI design
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // FROM DATE
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM DATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF94A3B8)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateFrom == null ? 'Start date...' : DateFormat('MMM dd, yyyy').format(_dateFrom!),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _dateFrom == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // TO DATE
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO DATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF94A3B8)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateTo == null ? 'End date...' : DateFormat('MMM dd, yyyy').format(_dateTo!),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _dateTo == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // STATUS Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STATUS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF94A3B8)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF94A3B8)),
                                  ),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // FILTER Button
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: _fetchDtrData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF214070),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'FILTER',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_dateFrom != null || _dateTo != null || _selectedStatus != null) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.clear_all_rounded),
                                  tooltip: 'Clear Filters',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Published Cutoff Period Cards
                ...cutoffItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Cutoff Period Label & Status Pill Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CUTOFF PERIOD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF216844),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Cutoff Range Text
                      Text(
                        item.formattedRange,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      const SizedBox(height: 16),
                      // Action Buttons Row: View PDF & Download PDF
                      Row(
                        children: [
                          // View PDF Button
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () => _viewPdfDetails(item),
                                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0F172A)),
                                label: const Text(
                                  'View PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Download PDF Button
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () => _downloadPdfReport(item),
                                icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.white),
                                label: const Text(
                                  'Download PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF214070),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

