import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportAttendanceTrend extends StatefulWidget {
  const OfficeReportAttendanceTrend({super.key});

  @override
  State<OfficeReportAttendanceTrend> createState() =>
      _OfficeReportAttendanceTrendState();
}

class _OfficeReportAttendanceTrendState
    extends State<OfficeReportAttendanceTrend> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportAttendanceTrend,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      setState(() {
        _rows = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Attendance Trend'),
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
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _rows.isEmpty
                        ? const ReportEmptyState(
                            message: 'No data for the selected period')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _rows.length,
                              itemBuilder: (_, i) => _TrendRow(_rows[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _TrendRow(this.r);

  @override
  Widget build(BuildContext context) {
    final date      = r['date']           as String? ?? '—';
    final total     = (r['totalStaff']    as num?)?.toInt() ?? 0;
    final present   = (r['presentCount']  as num?)?.toInt() ?? 0;
    final absent    = (r['absentCount']   as num?)?.toInt() ?? 0;
    final leave     = (r['leaveCount']    as num?)?.toInt() ?? 0;
    final notMarked = (r['notMarkedCount'] as num?)?.toInt() ?? 0;

    final pct = total > 0 ? present / total : 0.0;
    final pctColor = pct >= 0.9 ? AppColors.success
        : pct >= 0.7 ? AppColors.warning : AppColors.error;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip('P $present', AppColors.success),
                    const SizedBox(width: 4),
                    _Chip('A $absent', AppColors.error),
                    const SizedBox(width: 4),
                    _Chip('L $leave', const Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    _Chip('? $notMarked', AppColors.mutedText),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: pctColor, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 15)),
              Text('of $total',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }
}
