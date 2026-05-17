import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportWeightVariance extends StatefulWidget {
  const OfficeReportWeightVariance({super.key});

  @override
  State<OfficeReportWeightVariance> createState() =>
      _OfficeReportWeightVarianceState();
}

class _OfficeReportWeightVarianceState
    extends State<OfficeReportWeightVariance> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportWeightVariance,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? {};
        _data    = (d['lrs'] as List? ?? []).cast<Map<String, dynamic>>();
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
    final totalBilled  = (_summary['totalBilledWeight']  as num?)?.toDouble() ?? 0;
    final totalActual  = (_summary['totalActualWeight']  as num?)?.toDouble() ?? 0;
    final variance     = totalActual - totalBilled;
    final variancePct  = totalBilled > 0 ? (variance / totalBilled * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Weight Variance'),
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
              (label: 'Billed Weight',
                  value: '${totalBilled.toStringAsFixed(0)} kg', color: null),
              (label: 'Actual Weight',
                  value: '${totalActual.toStringAsFixed(0)} kg', color: null),
              (label: 'Variance',
                  value: '${variancePct >= 0 ? '+' : ''}${variancePct.toStringAsFixed(1)}%',
                  color: variancePct.abs() > 5
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF4ADE80)),
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
                              itemBuilder: (_, i) => _VarianceRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _VarianceRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _VarianceRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo   = r['lrNumber']      as String? ?? '—';
    final client = r['clientName']    as String? ?? '—';
    final billed = (r['billedWeight'] as num?)?.toDouble() ?? 0;
    final actual = (r['actualWeight'] as num?)?.toDouble() ?? 0;
    final diff   = actual - billed;
    final pct    = billed > 0 ? (diff / billed * 100) : 0.0;

    final color  = diff.abs() / billed.clamp(1, double.infinity) > 0.05
        ? AppColors.error
        : AppColors.mutedText;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lrNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(client,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 6),
          Row(
            children: [
              _WeightChip('Billed', billed, AppColors.navy),
              const SizedBox(width: 8),
              _WeightChip('Actual', actual,
                  diff.abs() > 0 ? color : AppColors.mutedText),
              if (diff != 0) ...[
                const SizedBox(width: 8),
                _WeightChip('Diff',
                    diff.abs(), diff > 0 ? AppColors.error : AppColors.success),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String label;
  final double kg;
  final Color color;
  const _WeightChip(this.label, this.kg, this.color);

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
