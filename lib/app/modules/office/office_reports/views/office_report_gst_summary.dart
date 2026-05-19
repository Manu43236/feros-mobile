import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportGstSummary extends StatefulWidget {
  const OfficeReportGstSummary({super.key});

  @override
  State<OfficeReportGstSummary> createState() => _OfficeReportGstSummaryState();
}

class _OfficeReportGstSummaryState extends State<OfficeReportGstSummary> {
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
        ApiEndpoints.reportGstSummary,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      setState(() {
        _data = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _totalSubtotal => _data.fold(
      0.0, (s, r) => s + ((r['subtotal'] as num?)?.toDouble() ?? 0));
  double get _totalCgst => _data.fold(
      0.0, (s, r) => s + ((r['cgstAmount'] as num?)?.toDouble() ?? 0));
  double get _totalSgst => _data.fold(
      0.0, (s, r) => s + ((r['sgstAmount'] as num?)?.toDouble() ?? 0));
  double get _totalTax => _data.fold(
      0.0, (s, r) => s + ((r['totalTax'] as num?)?.toDouble() ?? 0));
  int get _totalInvoices => _data.fold(
      0, (s, r) => s + ((r['invoiceCount'] as num?)?.toInt() ?? 0));

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
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('GST Summary'),
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
              (label: 'Taxable',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalSubtotal),
                  color: null),
              (label: 'Total Tax',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalTax),
                  color: AppColors.warning),
              (label: 'Invoices',
                  value: '$_totalInvoices', color: null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState(message: 'No GST data for this period')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              children: [
                                if (_totalCgst > 0 || _totalSgst > 0)
                                  _TaxCard(
                                    title: 'Tax Breakup',
                                    items: [
                                      if (_totalCgst > 0)
                                        ('CGST', _totalCgst, const Color(0xFF0284C7)),
                                      if (_totalSgst > 0)
                                        ('SGST', _totalSgst, const Color(0xFF7C3AED)),
                                    ],
                                  ),
                                if (_totalCgst > 0 || _totalSgst > 0)
                                  const SizedBox(height: 12),
                                Text('Monthly Breakdown',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.mutedText,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4)),
                                const SizedBox(height: 8),
                                ..._data.map((r) => _GstMonthRow(r)),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final String title;
  final List<(String, double, Color)> items;
  final Map<int, bool>? isCount;
  const _TaxCard({required this.title, required this.items, this.isCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 12),
          Row(
            children: items.asMap().entries.map((e) {
              final (label, val, color) = e.value;
              final cnt = isCount?[e.key] ?? false;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      cnt
                          ? '${val.toInt()}'
                          : FerosNumberUtils.formatCurrencyCompact(val),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800,
                          fontFamily: 'Inter', fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(label,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GstMonthRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _GstMonthRow(this.r);

  @override
  Widget build(BuildContext context) {
    final period   = r['period']      as String? ?? '—';
    final subtotal = (r['subtotal']   as num?)?.toDouble() ?? 0;
    final cgst     = (r['cgstAmount'] as num?)?.toDouble() ?? 0;
    final sgst     = (r['sgstAmount'] as num?)?.toDouble() ?? 0;
    final tax      = (r['totalTax']   as num?)?.toDouble() ?? cgst + sgst;
    final count    = (r['invoiceCount'] as num?)?.toInt() ?? 0;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.bodyText)),
                const SizedBox(height: 2),
                Text('Taxable: ${FerosNumberUtils.formatCurrencyCompact(subtotal)}'
                    '  ·  $count inv',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (cgst > 0 || sgst > 0)
                  Text('CGST ${FerosNumberUtils.formatCurrencyCompact(cgst)}'
                      '  SGST ${FerosNumberUtils.formatCurrencyCompact(sgst)}',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(FerosNumberUtils.formatCurrencyCompact(tax),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.warning)),
              Text('tax', style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
