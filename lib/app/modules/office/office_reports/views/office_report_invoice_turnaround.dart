import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportInvoiceTurnaround extends StatefulWidget {
  const OfficeReportInvoiceTurnaround({super.key});

  @override
  State<OfficeReportInvoiceTurnaround> createState() =>
      _OfficeReportInvoiceTurnaroundState();
}

class _OfficeReportInvoiceTurnaroundState
    extends State<OfficeReportInvoiceTurnaround> {
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
        ApiEndpoints.reportInvoiceTurnaround,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? {};
        _data    = (d['invoices'] as List? ?? []).cast<Map<String, dynamic>>();
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
    final avg   = (_summary['avgDays'] as num?)?.toDouble() ?? 0;
    final under3 = (_summary['under3Days'] as num?)?.toInt() ?? 0;
    final over7  = (_summary['over7Days']  as num?)?.toInt() ?? 0;
    final total  = (_summary['total']      as num?)?.toInt() ?? _data.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Invoice Turnaround'),
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
          if (!_loading && total > 0)
            ReportSummaryStrip.items([
              (label: 'Avg Turnaround', value: '${avg.toStringAsFixed(1)} days',
                  color: avg <= 3
                      ? const Color(0xFF4ADE80)
                      : avg <= 7 ? AppColors.warning : const Color(0xFFFCA5A5)),
              (label: '≤3 days', value: '$under3', color: const Color(0xFF4ADE80)),
              (label: '>7 days', value: '$over7',
                  color: over7 > 0 ? const Color(0xFFFCA5A5) : null),
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
                              itemBuilder: (_, i) =>
                                  _TurnaroundRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TurnaroundRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _TurnaroundRow(this.r);

  @override
  Widget build(BuildContext context) {
    final invNo  = r['invoiceNumber'] as String? ?? '—';
    final client = r['clientName']    as String? ?? '—';
    final lrNo   = r['lrNumber']      as String?;
    final days   = (r['turnaroundDays'] as num?)?.toInt() ?? 0;

    final color = days <= 3 ? AppColors.success
        : days <= 7 ? AppColors.warning : AppColors.error;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(client,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                if (lrNo != null)
                  Text('LR: $lrNo',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text('$days days',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700,
                    fontFamily: 'Inter', fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
