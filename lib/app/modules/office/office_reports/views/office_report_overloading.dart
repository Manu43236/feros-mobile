import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportOverloading extends StatefulWidget {
  const OfficeReportOverloading({super.key});

  @override
  State<OfficeReportOverloading> createState() =>
      _OfficeReportOverloadingState();
}

class _OfficeReportOverloadingState extends State<OfficeReportOverloading> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic> _summary = {};
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportOverloading,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      final list = (d['lrs'] as List? ?? d['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['excessKg'] as num?) ?? 0)
          .compareTo((a['excessKg'] as num?) ?? 0));
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? {};
        _data    = list;
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
    final count    = (_summary['count']    as num?)?.toInt() ?? _data.length;
    final maxExcess = (_summary['maxExcessKg'] as num?)?.toDouble() ?? 0;
    final avgExcess = (_summary['avgExcessKg'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: const Text('Overloading'),
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
          if (!_loading && count > 0)
            ReportSummaryStrip.items([
              (label: 'Overloaded LRs', value: '$count',
                  color: const Color(0xFFFCA5A5)),
              (label: 'Max Excess', value: '${maxExcess.toStringAsFixed(0)} kg',
                  color: const Color(0xFFFCA5A5)),
              (label: 'Avg Excess', value: '${avgExcess.toStringAsFixed(0)} kg',
                  color: null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState(
                            message: 'No overloading incidents in this period')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _OverloadRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OverloadRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _OverloadRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo    = r['lrNumber']      as String? ?? '—';
    final vehicle = r['vehicleNumber'] as String? ?? '—';
    final allowed = (r['allowedWeight'] as num?)?.toDouble() ?? 0;
    final actual  = (r['actualWeight']  as num?)?.toDouble() ?? 0;
    final excess  = (r['excessKg']      as num?)?.toDouble() ?? actual - allowed;
    final excessPct = allowed > 0 ? (excess / allowed * 100) : 0.0;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lrNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              Text('+${excessPct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w800,
                      fontFamily: 'Inter', fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(vehicle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _KgChip('Allowed', allowed, AppColors.success),
              const SizedBox(width: 10),
              _KgChip('Actual',  actual,  AppColors.error),
              const SizedBox(width: 10),
              _KgChip('Excess',  excess,  AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _KgChip extends StatelessWidget {
  final String label;
  final double kg;
  final Color color;
  const _KgChip(this.label, this.kg, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 10)),
        Text('${kg.toStringAsFixed(0)} kg',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600,
                fontFamily: 'Inter', fontSize: 13)),
      ],
    );
  }
}
