import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportAttendanceGaps extends StatefulWidget {
  const OfficeReportAttendanceGaps({super.key});

  @override
  State<OfficeReportAttendanceGaps> createState() =>
      _OfficeReportAttendanceGapsState();
}

class _OfficeReportAttendanceGapsState
    extends State<OfficeReportAttendanceGaps> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportAttendanceGaps,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['totalGapDays'] as num?) ?? 0)
          .compareTo((a['totalGapDays'] as num?) ?? 0));
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

  @override
  Widget build(BuildContext context) {
    final critical = _data.where((r) =>
        ((r['totalGapDays'] as num?) ?? 0) > 7).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Attendance Gaps'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset,
            onPickFrom: () async {
              final d = await pickDate(context, initial: _from, last: _to);
              if (d != null) { setState(() { _from = d; _preset = 'custom'; }); _fetch(); }
            },
            onPickTo: () async {
              final d = await pickDate(context, initial: _to, first: _from);
              if (d != null) { setState(() { _to = d; _preset = 'custom'; }); _fetch(); }
            },
          ),
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Staff with Gaps', value: '${_data.length}', color: null),
              (label: 'Critical (>7d)', value: '$critical',
                  color: critical > 0 ? const Color(0xFFFCA5A5) : null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState(
                            message: 'No attendance gaps in this period')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _GapRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _GapRow(this.r);

  @override
  Widget build(BuildContext context) {
    final name      = r['userName']      as String? ?? '—';
    final role      = r['roleName']      as String? ?? '';
    final gapDays   = (r['totalGapDays'] as num?)?.toInt() ?? 0;
    final gapDates  = (r['gapDates']     as List? ?? []).cast<String>();

    final isCritical = gapDays > 7;
    final isWarning  = !isCritical && gapDays > 3;
    final badgeColor = isCritical ? AppColors.error
        : isWarning ? AppColors.warning : AppColors.mutedText;

    final preview = gapDates.take(5).join(', ') +
        (gapDates.length > 5 ? ' +${gapDates.length - 5} more' : '');

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person_remove_outlined, size: 18, color: badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (role.isNotEmpty)
                  Text(_roleLabel(role),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                if (gapDates.isNotEmpty)
                  Text(preview,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('$gapDays',
                    style: TextStyle(
                        color: badgeColor, fontWeight: FontWeight.w800,
                        fontFamily: 'Inter', fontSize: 16)),
                Text('gap days',
                    style: AppTextStyles.caption.copyWith(
                        color: badgeColor, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) => r.replaceAll('_', ' ').toLowerCase()
      .split(' ').map((w) => w.isNotEmpty
          ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}
