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
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _breakdown = [];
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
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary   = d['summary']   as Map<String, dynamic>? ?? d;
        _breakdown = (d['breakdown'] as List? ?? []).cast<Map<String, dynamic>>();
        _loading   = false;
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
    final taxable   = (_summary['taxableAmount'] as num?)?.toDouble() ?? 0;
    final cgst      = (_summary['cgst']          as num?)?.toDouble() ?? 0;
    final sgst      = (_summary['sgst']          as num?)?.toDouble() ?? 0;
    final igst      = (_summary['igst']          as num?)?.toDouble() ?? 0;
    final totalTax  = (_summary['totalTax']      as num?)?.toDouble()
        ?? cgst + sgst + igst;
    final invoicesCnt = (_summary['invoiceCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
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
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        color: AppColors.navy,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            // Tax summary tiles
                            _TaxCard(
                              title: 'Tax Summary',
                              items: [
                                ('Taxable Amount', taxable, AppColors.navy),
                                ('Total Tax',      totalTax, AppColors.success),
                                ('Invoices',       invoicesCnt.toDouble(),
                                    AppColors.mutedText),
                              ],
                              isCount: {2: true},
                            ),
                            const SizedBox(height: 12),
                            if (cgst > 0 || sgst > 0 || igst > 0)
                              _TaxCard(
                                title: 'Tax Breakup',
                                items: [
                                  if (cgst > 0) ('CGST', cgst, const Color(0xFF0284C7)),
                                  if (sgst > 0) ('SGST', sgst, const Color(0xFF7C3AED)),
                                  if (igst > 0) ('IGST', igst, const Color(0xFF059669)),
                                ],
                              ),
                            if (_breakdown.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('By Tax Rate',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.mutedText,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4)),
                              const SizedBox(height: 8),
                              ..._breakdown.map((r) => _GstRateRow(r)),
                            ],
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

class _GstRateRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _GstRateRow(this.r);

  @override
  Widget build(BuildContext context) {
    final rate    = r['gstRate']       as String? ?? '—';
    final taxable = (r['taxableAmount'] as num?)?.toDouble() ?? 0;
    final tax     = (r['taxAmount']     as num?)?.toDouble() ?? 0;
    final count   = (r['invoiceCount']  as num?)?.toInt() ?? 0;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$rate%',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taxable: ${FerosNumberUtils.formatCurrencyCompact(taxable)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                Text('$count invoice${count != 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Text(FerosNumberUtils.formatCurrencyCompact(tax),
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.success)),
        ],
      ),
    );
  }
}
