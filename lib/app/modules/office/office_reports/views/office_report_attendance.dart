import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import 'report_widgets.dart';

class OfficeReportAttendance extends StatefulWidget {
  const OfficeReportAttendance({super.key});

  @override
  State<OfficeReportAttendance> createState() =>
      _OfficeReportAttendanceState();
}

class _OfficeReportAttendanceState extends State<OfficeReportAttendance> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';
  String _search = '';

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportAttendance,
        params: {
          'from': fmtApiDate(_from),
          'to':   fmtApiDate(_to),
        },
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Sort: worst attendance % first
      list.sort((a, b) =>
          ((a['attendancePercentage'] as num?) ?? 0)
              .compareTo((b['attendancePercentage'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _setPreset(String p) {
    if (p == 'custom') { setState(() => _preset = 'custom'); return; }
    final (f, t) = presetDates(p);
    setState(() { _from = f; _to = t; _preset = p; });
    _fetch();
  }

  Future<void> _pickFrom() async {
    final d = await pickDate(context, initial: _from, last: _to);
    if (d != null) { setState(() { _from = d; _preset = 'custom'; }); _fetch(); }
  }

  Future<void> _pickTo() async {
    final d = await pickDate(context, initial: _to, first: _from);
    if (d != null) { setState(() { _to = d; _preset = 'custom'; }); _fetch(); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['userName'] as String? ?? '').toLowerCase().contains(q) ||
        (r['roleName'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  double get _avgPct {
    if (_data.isEmpty) return 0;
    final sum = _data.fold(0.0,
        (s, r) => s + ((r['attendancePercentage'] as num?) ?? 0).toDouble());
    return sum / _data.length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Attendance Summary'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset,
            onPickFrom: _pickFrom, onPickTo: _pickTo,
          ),
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Staff',    value: '${_data.length}', color: null),
              (label: 'Avg',      value: '${_avgPct.toStringAsFixed(1)}%', color: null),
              (label: 'Low (<60%)', value: '${_data.where((r) => ((r['attendancePercentage'] as num?) ?? 100) < 60).length}',
               color: const Color(0xFFFCA5A5)),
            ]),
          ReportSearchBar(
            hint: 'Search staff name…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _AttendanceRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _AttendanceRow(this.r);

  @override
  Widget build(BuildContext context) {
    final name    = r['userName']              as String? ?? '—';
    final role    = r['roleName']              as String? ?? '';
    final present = r['presentDays']           as int? ?? 0;
    final absent  = r['absentDays']            as int? ?? 0;
    final half    = r['halfDays']              as int? ?? 0;
    final leave   = r['leaveDays']             as int? ?? 0;
    final pct     = (r['attendancePercentage'] as num?)?.toDouble() ?? 0;

    final barColor = pct >= 80
        ? AppColors.success
        : pct >= 60
            ? AppColors.warning
            : AppColors.error;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  FerosStringUtils.initials(name),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(FerosStringUtils.roleLabel(role),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PillStat('P', '$present', AppColors.success),
              const SizedBox(width: 6),
              _PillStat('A', '$absent', AppColors.error),
              const SizedBox(width: 6),
              _PillStat('H', '$half', AppColors.warning),
              const SizedBox(width: 6),
              _PillStat('L', '$leave', AppColors.info),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PillStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$label: $value',
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
