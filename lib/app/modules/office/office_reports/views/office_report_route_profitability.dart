import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportRouteProfitability extends StatefulWidget {
  const OfficeReportRouteProfitability({super.key});

  @override
  State<OfficeReportRouteProfitability> createState() =>
      _OfficeReportRouteProfitabilityState();
}

class _OfficeReportRouteProfitabilityState
    extends State<OfficeReportRouteProfitability> {
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
        ApiEndpoints.reportRouteProfitability,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['margin'] as num?) ?? 0)
          .compareTo((a['margin'] as num?) ?? 0));
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

  double get _totalRevenue => _data.fold(
      0.0, (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0));
  double get _totalMargin => _data.fold(
      0.0, (s, r) => s + ((r['margin'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Route Profitability'),
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
              (label: 'Revenue',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalRevenue),
                  color: const Color(0xFF4ADE80)),
              (label: 'Net Margin',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalMargin),
                  color: _totalMargin >= 0
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFCA5A5)),
              (label: 'Routes', value: '${_data.length}', color: null),
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
                              itemBuilder: (_, i) => _RouteRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _RouteRow(this.r);

  @override
  Widget build(BuildContext context) {
    final route   = r['routeName']  as String? ?? '—';
    final revenue = (r['revenue']   as num?)?.toDouble() ?? 0;
    final cost    = (r['cost']      as num?)?.toDouble() ?? 0;
    final margin  = (r['margin']    as num?)?.toDouble() ?? revenue - cost;
    final trips   = (r['tripCount'] as num?)?.toInt() ?? 0;
    final marginPct = revenue > 0 ? (margin / revenue * 100) : 0.0;

    final color = marginPct >= 30 ? AppColors.success
        : marginPct >= 10 ? AppColors.warning : AppColors.error;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(route,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${marginPct.toStringAsFixed(0)}% margin',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            _FinChip('Revenue', revenue, AppColors.success),
            const SizedBox(width: 12),
            _FinChip('Cost', cost, AppColors.mutedText),
            const SizedBox(width: 12),
            _FinChip('Margin', margin, color),
          ]),
          const SizedBox(height: 6),
          Text('$trips trip${trips != 1 ? 's' : ''}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

class _FinChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _FinChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 10)),
        Text(FerosNumberUtils.formatCurrencyCompact(value),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600,
                fontFamily: 'Inter', fontSize: 13)),
      ],
    );
  }
}
