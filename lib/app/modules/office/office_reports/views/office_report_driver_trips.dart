import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportDriverTrips extends StatefulWidget {
  const OfficeReportDriverTrips({super.key});

  @override
  State<OfficeReportDriverTrips> createState() =>
      _OfficeReportDriverTripsState();
}

class _OfficeReportDriverTripsState extends State<OfficeReportDriverTrips> {
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
        ApiEndpoints.reportDriverPerformance,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['tripCount'] as num?) ?? 0)
          .compareTo((a['tripCount'] as num?) ?? 0));
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

  int get _totalTrips =>
      _data.fold(0, (s, r) => s + ((r['tripCount'] as num?)?.toInt() ?? 0));

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
        title: const Text('Driver Performance'),
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
              (label: 'Total Trips', value: '$_totalTrips', color: null),
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
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _DriverRow(_data[i], rank: i + 1),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  final Map<String, dynamic> r;
  final int rank;
  const _DriverRow(this.r, {required this.rank});

  @override
  Widget build(BuildContext context) {
    final name      = r['driverName']       as String? ?? '—';
    final trips     = (r['tripCount']        as num?)?.toInt() ?? 0;
    final kmTotal   = (r['totalKm']          as num?)?.toDouble() ?? 0;
    final onTimePct = (r['onTimePercentage'] as num?)?.toDouble();

    final rankColor = rank == 1 ? const Color(0xFFF59E0B)
        : rank == 2 ? const Color(0xFF9CA3AF)
        : rank == 3 ? const Color(0xFFCD7F32)
        : AppColors.navy;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('#$rank',
                style: TextStyle(
                    color: rankColor, fontWeight: FontWeight.w800,
                    fontFamily: 'Inter', fontSize: 14)),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('$trips trip${trips != 1 ? 's' : ''}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                    if (kmTotal > 0) ...[
                      const SizedBox(width: 8),
                      Text('${kmTotal.toStringAsFixed(0)} km',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onTimePct != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${onTimePct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: onTimePct >= 90 ? AppColors.success
                            : onTimePct >= 70 ? AppColors.warning : AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter', fontSize: 14)),
                Text('on time',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }
}
