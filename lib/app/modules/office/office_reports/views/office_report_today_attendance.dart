import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportTodayAttendance extends StatefulWidget {
  const OfficeReportTodayAttendance({super.key});

  @override
  State<OfficeReportTodayAttendance> createState() =>
      _OfficeReportTodayAttendanceState();
}

class _OfficeReportTodayAttendanceState
    extends State<OfficeReportTodayAttendance> {
  final _api = Get.find<ApiClient>();

  bool _loading = true;
  Map<String, dynamic> _meta = {};
  List<Map<String, dynamic>> _records = [];
  String? _error;
  String _search = '';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportTodayAttendance);
      final data = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _meta    = data;
        _records = (data['records'] as List? ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _records;
    final q = _search.toLowerCase();
    return _records.where((r) =>
        (r['userName'] as String? ?? '').toLowerCase().contains(q) ||
        (r['roleName'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  // Normalize to uppercase so "Present", "PRESENT", "present" all match
  List<Map<String, dynamic>> _byStatus(List<Map<String, dynamic>> list, String status) =>
      list.where((r) =>
          (r['attendanceStatus'] as String? ?? '').toUpperCase() == status).toList();

  @override
  Widget build(BuildContext context) {
    final totalStaff   = (_meta['totalStaff'] as num?)?.toInt() ?? _records.length;
    // Count from records so the numbers always match what's shown in the list
    final presentCount = _records.where((r) =>
        (r['attendanceStatus'] as String? ?? '').toUpperCase() == 'PRESENT').length;
    final absentCount  = _records.where((r) =>
        (r['attendanceStatus'] as String? ?? '').toUpperCase() == 'ABSENT').length;
    final pct          = totalStaff > 0 ? presentCount / totalStaff : 0.0;

    final filtered   = _filtered;
    final present    = _byStatus(filtered, 'PRESENT');
    final absent     = _byStatus(filtered, 'ABSENT');
    final onLeave    = _byStatus(filtered, 'LEAVE');
    final notMarkedL = _byStatus(filtered, 'NOT_MARKED');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text("Today's Attendance"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : Column(
                  children: [
                    ReportSummaryStrip.items([
                      (label: 'Total Staff', value: '$totalStaff', color: null),
                      (label: 'Present',     value: '$presentCount',
                          color: const Color(0xFF4ADE80)),
                      (label: 'Absent',      value: '$absentCount',
                          color: absentCount > 0
                              ? const Color(0xFFFCA5A5) : null),
                      (label: 'Rate',
                          value: '${(pct * 100).toStringAsFixed(0)}%',
                          color: pct >= 0.9
                              ? const Color(0xFF4ADE80)
                              : pct >= 0.7
                                  ? AppColors.warning
                                  : const Color(0xFFFCA5A5)),
                    ]),
                    ReportSearchBar(
                      hint: 'Search staff…',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    Expanded(
                      child: _records.isEmpty
                          ? const ReportEmptyState(
                              message: 'No attendance data for today')
                          : RefreshIndicator(
                              onRefresh: _fetch,
                              color: AppColors.navy,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                children: [
                                  if (present.isNotEmpty) ...[
                                    _StatusHeader('Present (${present.length})',
                                        AppColors.success),
                                    ...present.map((r) => _StaffRow(r)),
                                  ],
                                  if (absent.isNotEmpty) ...[
                                    _StatusHeader('Absent (${absent.length})',
                                        AppColors.error),
                                    ...absent.map((r) => _StaffRow(r)),
                                  ],
                                  if (onLeave.isNotEmpty) ...[
                                    _StatusHeader('On Leave (${onLeave.length})',
                                        AppColors.warning),
                                    ...onLeave.map((r) => _StaffRow(r)),
                                  ],
                                  if (notMarkedL.isNotEmpty) ...[
                                    _StatusHeader(
                                        'Not Marked (${notMarkedL.length})',
                                        AppColors.mutedText),
                                    ...notMarkedL.map((r) => _StaffRow(r)),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusHeader(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _StaffRow(this.r);

  static const _statusColor = {
    'PRESENT':    AppColors.success,
    'ABSENT':     AppColors.error,
    'LEAVE':      AppColors.warning,
    'NOT_MARKED': AppColors.mutedText,
  };

  static const _statusIcon = {
    'PRESENT':    Icons.check_circle_outline,
    'ABSENT':     Icons.cancel_outlined,
    'LEAVE':      Icons.beach_access_outlined,
    'NOT_MARKED': Icons.radio_button_unchecked,
  };

  @override
  Widget build(BuildContext context) {
    final name   = r['userName']        as String? ?? '—';
    final role   = r['roleName']        as String? ?? '—';
    final status = r['attendanceStatus'] as String? ?? 'NOT_MARKED';
    final time   = r['checkInTime']     as String?;
    final phone  = r['phone']           as String?;

    final color = _statusColor[status] ?? AppColors.mutedText;
    final icon  = _statusIcon[status]  ?? Icons.radio_button_unchecked;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(_roleLabel(role),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (phone != null)
                  Text(phone,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          if (time != null)
            Text(_shortTime(time),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w600))
          else
            Text(_statusLabel(status),
                style: AppTextStyles.caption.copyWith(
                    color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _roleLabel(String r) => r.replaceAll('_', ' ').toLowerCase()
      .split(' ').map((w) => w.isNotEmpty
          ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  String _statusLabel(String s) {
    switch (s) {
      case 'NOT_MARKED': return 'Not marked';
      case 'PRESENT':    return 'Present';
      case 'ABSENT':     return 'Absent';
      case 'LEAVE':      return 'On leave';
      default:           return s;
    }
  }

  String _shortTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(11, 16) : iso;
    }
  }
}
