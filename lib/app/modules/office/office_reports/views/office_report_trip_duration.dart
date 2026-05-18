import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportTripDuration extends StatefulWidget {
  const OfficeReportTripDuration({super.key});

  @override
  State<OfficeReportTripDuration> createState() =>
      _OfficeReportTripDurationState();
}

class _OfficeReportTripDurationState extends State<OfficeReportTripDuration> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _routes = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportTripDuration,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? {};
        _routes  = (d['byRoute'] as List? ?? []).cast<Map<String, dynamic>>();
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
    final avgHours = (_summary['avgDurationHours'] as num?)?.toDouble() ?? 0;
    final minHours = (_summary['minDurationHours'] as num?)?.toDouble() ?? 0;
    final maxHours = (_summary['maxDurationHours'] as num?)?.toDouble() ?? 0;
    final tripCnt  = (_summary['tripCount']        as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Trip Duration'),
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
          if (!_loading && tripCnt > 0)
            ReportSummaryStrip.items([
              (label: 'Avg Duration', value: _fmtHours(avgHours), color: null),
              (label: 'Fastest',      value: _fmtHours(minHours), color: const Color(0xFF4ADE80)),
              (label: 'Slowest',      value: _fmtHours(maxHours), color: null),
              (label: 'Trips',        value: '$tripCnt',           color: null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _routes.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _routes.length,
                              itemBuilder: (_, i) => _RouteRow(_routes[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  static String _fmtHours(double h) {
    if (h >= 24) return '${(h / 24).toStringAsFixed(1)}d';
    return '${h.toStringAsFixed(1)}h';
  }
}

class _RouteRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _RouteRow(this.r);

  @override
  Widget build(BuildContext context) {
    final route    = r['routeName']       as String? ?? '—';
    final avgH     = (r['avgDurationHours'] as num?)?.toDouble() ?? 0;
    final tripCnt  = (r['tripCount']       as num?)?.toInt() ?? 0;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.alt_route_outlined, size: 18,
                color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$tripCnt trip${tripCnt != 1 ? 's' : ''}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          Text(_fmtH(avgH),
              style: TextStyle(
                  color: const Color(0xFF7C3AED), fontWeight: FontWeight.w700,
                  fontFamily: 'Inter', fontSize: 15)),
        ],
      ),
    );
  }

  static String _fmtH(double h) {
    if (h >= 24) return '${(h / 24).toStringAsFixed(1)}d';
    return '${h.toStringAsFixed(1)}h';
  }
}
