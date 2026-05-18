import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportInvoiceAging extends StatefulWidget {
  const OfficeReportInvoiceAging({super.key});

  @override
  State<OfficeReportInvoiceAging> createState() =>
      _OfficeReportInvoiceAgingState();
}

class _OfficeReportInvoiceAgingState extends State<OfficeReportInvoiceAging> {
  final _api = Get.find<ApiClient>();
  bool _loading = true;
  Map<String, dynamic> _buckets = {};
  List<Map<String, dynamic>> _invoices = [];
  String? _error;
  String _selectedBucket = 'all';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportInvoiceAging);
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      final all = (d['invoices'] as List? ?? []).cast<Map<String, dynamic>>();
      all.sort((a, b) => ((b['daysOverdue'] as num?) ?? 0)
          .compareTo((a['daysOverdue'] as num?) ?? 0));
      setState(() {
        _buckets  = d['buckets'] as Map<String, dynamic>? ?? {};
        _invoices = all;
        _loading  = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedBucket == 'all') return _invoices;
    return _invoices.where((r) {
      final days = (r['daysOverdue'] as num?)?.toInt() ?? 0;
      switch (_selectedBucket) {
        case 'current': return days <= 0;
        case '1_30':    return days > 0 && days <= 30;
        case '31_60':   return days > 30 && days <= 60;
        case '60plus':  return days > 60;
        default:        return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalOutstanding = _filtered.fold(0.0,
        (s, r) => s + ((r['balanceDue'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Invoice Aging'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : Column(
                  children: [
                    if (_invoices.isNotEmpty)
                      ReportSummaryStrip.items([
                        (label: 'Total Outstanding',
                            value: FerosNumberUtils.formatCurrencyCompact(
                                _invoices.fold<double>(0.0, (s, r) =>
                                    s + ((r['balanceDue'] as num?)?.toDouble() ?? 0.0))),
                            color: null),
                        (label: '${_filtered.length} invoices',
                            value: FerosNumberUtils.formatCurrencyCompact(totalOutstanding),
                            color: null),
                      ]),
                    _BucketFilter(
                      buckets: _buckets,
                      selected: _selectedBucket,
                      onSelect: (b) => setState(() => _selectedBucket = b),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const ReportEmptyState(
                              message: 'No invoices in this aging bucket')
                          : RefreshIndicator(
                              onRefresh: _fetch,
                              color: AppColors.navy,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _AgingInvoiceRow(_filtered[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _BucketFilter extends StatelessWidget {
  final Map<String, dynamic> buckets;
  final String selected;
  final ValueChanged<String> onSelect;
  const _BucketFilter({
    required this.buckets, required this.selected, required this.onSelect});

  static final _options = [
    ('all',     'All',      AppColors.navy),
    ('current', 'Current',  AppColors.success),
    ('1_30',    '1–30d',    AppColors.warning),
    ('31_60',   '31–60d',   AppColors.orange),
    ('60plus',  '60+ days', AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _options.map((opt) {
            final (id, label, color) = opt;
            final isSelected = selected == id;
            final bucketData = buckets[id] as Map?;
            final count = (bucketData?['count'] as num?)?.toInt();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? color : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: AppTextStyles.caption.copyWith(
                              color: isSelected ? Colors.white : AppColors.bodyText,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal)),
                      if (count != null) ...[
                        const SizedBox(width: 4),
                        Text('($count)',
                            style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.mutedText,
                                fontSize: 10)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AgingInvoiceRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _AgingInvoiceRow(this.r);

  @override
  Widget build(BuildContext context) {
    final invNo   = r['invoiceNumber'] as String? ?? '—';
    final client  = r['clientName']    as String? ?? '—';
    final balance = (r['balanceDue']   as num?)?.toDouble() ?? 0;
    final days    = (r['daysOverdue']  as num?)?.toInt() ?? 0;

    final isOverdue = days > 0;
    final color     = days > 60 ? AppColors.error
        : days > 30 ? AppColors.orange
        : days > 0  ? AppColors.warning
        : AppColors.success;

    final daysLabel = days <= 0 ? 'Current'
        : '${days}d overdue';

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
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(FerosNumberUtils.formatCurrencyCompact(balance),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOverdue ? color : AppColors.bodyText)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(daysLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: color, fontWeight: FontWeight.w600,
                        fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
