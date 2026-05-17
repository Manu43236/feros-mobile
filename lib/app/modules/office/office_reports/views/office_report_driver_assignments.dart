import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportDriverAssignments extends StatefulWidget {
  const OfficeReportDriverAssignments({super.key});

  @override
  State<OfficeReportDriverAssignments> createState() =>
      _OfficeReportDriverAssignmentsState();
}

class _OfficeReportDriverAssignmentsState
    extends State<OfficeReportDriverAssignments> {
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
        ApiEndpoints.reportDriverAssignments,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['assignmentCount'] as num?) ?? 0)
          .compareTo((a['assignmentCount'] as num?) ?? 0));
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

  int get _totalAssignments =>
      _data.fold(0, (s, r) => s + ((r['assignmentCount'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        title: const Text('Driver Assignments'),
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
              (label: 'Drivers', value: '${_data.length}', color: null),
              (label: 'Total Assignments', value: '$_totalAssignments', color: null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) =>
                                  _AssignmentRow(_data[i], rank: i + 1,
                                      max: _totalAssignments),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final Map<String, dynamic> r;
  final int rank;
  final int max;
  const _AssignmentRow(this.r, {required this.rank, required this.max});

  @override
  Widget build(BuildContext context) {
    final name   = r['driverName']      as String? ?? '—';
    final count  = (r['assignmentCount'] as num?)?.toInt() ?? 0;
    final pct    = max > 0 ? count / max : 0.0;

    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF9CA3AF)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.navy;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('#$rank',
                    style: TextStyle(
                        color: rankColor, fontWeight: FontWeight.w800,
                        fontFamily: 'Inter', fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text('$count trips',
                  style: TextStyle(
                      color: AppColors.navy, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),
        ],
      ),
    );
  }
}
