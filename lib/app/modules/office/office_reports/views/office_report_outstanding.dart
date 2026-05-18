import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportOutstanding extends StatefulWidget {
  const OfficeReportOutstanding({super.key});

  @override
  State<OfficeReportOutstanding> createState() =>
      _OfficeReportOutstandingState();
}

class _OfficeReportOutstandingState extends State<OfficeReportOutstanding> {
  final _api = Get.find<ApiClient>();

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportInvoiceOutstanding);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Sort: most overdue first
      list.sort((a, b) =>
          ((b['daysOverdue'] as num?) ?? 0)
              .compareTo((a['daysOverdue'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['invoiceNumber'] as String? ?? '').toLowerCase().contains(q) ||
        (r['clientName']   as String? ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalOutstanding => _filtered.fold(0,
      (s, r) => s + ((r['balanceDue'] as num?) ?? 0).toDouble());

  int get _overdueCount =>
      _filtered.where((r) => ((r['daysOverdue'] as num?) ?? 0) > 0).length;

  // Aging buckets from the full dataset (not filtered)
  ({double current, double d30, double d60, double d60plus,
    int cCount, int d30Count, int d60Count, int d60plusCount})
      get _aging {
    double current = 0, d30 = 0, d60 = 0, d60plus = 0;
    int cC = 0, c30 = 0, c60 = 0, c60p = 0;
    for (final r in _data) {
      final days = ((r['daysOverdue'] as num?) ?? 0).toInt();
      final bal  = (r['balanceDue']  as num?)?.toDouble() ?? 0;
      if (days <= 0)       { current += bal;  cC++;  }
      else if (days <= 30) { d30     += bal;  c30++; }
      else if (days <= 60) { d60     += bal;  c60++; }
      else                 { d60plus += bal;  c60p++; }
    }
    return (current: current, d30: d30, d60: d60, d60plus: d60plus,
        cCount: cC, d30Count: c30, d60Count: c60, d60plusCount: c60p);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Invoice Outstanding'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          if (!_loading && _data.isNotEmpty) ...[
            ReportSummaryStrip.items([
              (
                label: 'Total Outstanding',
                value: FerosNumberUtils.formatCurrencyCompact(_totalOutstanding),
                color: null,
              ),
              (
                label: 'Invoices',
                value: '${filtered.length}',
                color: null,
              ),
              (
                label: 'Overdue',
                value: '$_overdueCount',
                color: _overdueCount > 0
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF4ADE80),
              ),
            ]),
            _AgingStrip(aging: _aging),
          ],
          ReportSearchBar(
            hint: 'Search invoice#, client…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState(
                            message: 'No outstanding invoices')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _OutstandingRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _OutstandingRow(this.r);

  @override
  Widget build(BuildContext context) {
    final invNo   = r['invoiceNumber'] as String? ?? '—';
    final client  = r['clientName']    as String? ?? '—';
    final balance = (r['balanceDue']   as num?)?.toDouble() ?? 0;
    final total   = (r['totalAmount']  as num?)?.toDouble() ?? 0;
    final paid    = (r['amountPaid']   as num?)?.toDouble() ?? 0;
    final days    = (r['daysOverdue']  as num?)?.toInt() ?? 0;
    final dueDate = r['dueDate']       as String?;

    final isOverdue  = days > 0;
    final dueSoon    = !isOverdue && dueDate != null &&
        _daysUntil(dueDate) <= 7 && _daysUntil(dueDate) >= 0;

    final badgeColor = isOverdue
        ? AppColors.error
        : dueSoon
            ? AppColors.warning
            : AppColors.success;

    final badgeLabel = isOverdue
        ? '${days}d overdue'
        : dueSoon
            ? 'Due in ${_daysUntil(dueDate)}d'
            : dueDate != null
                ? 'Due ${dueDate.substring(0, 10)}'
                : '—';

    // Partial payment progress
    final pct = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(invNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTextStyles.caption.copyWith(
                      color: badgeColor, fontWeight: FontWeight.w700,
                      fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(client,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance Due',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                  Text(
                    FerosNumberUtils.formatCurrency(balance),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.bodyText),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('of ${FerosNumberUtils.formatCurrency(total)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                  Text('Paid ${FerosNumberUtils.formatCurrency(paid)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
                ],
              ),
            ],
          ),
          if (pct > 0 && pct < 1) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: Colors.black12,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _daysUntil(String iso) {
    try {
      return DateTime.parse(iso).difference(DateTime.now()).inDays;
    } catch (_) {
      return 999;
    }
  }
}

// ── Aging analysis strip ──────────────────────────────────────────────────────

class _AgingStrip extends StatelessWidget {
  final ({double current, double d30, double d60, double d60plus,
    int cCount, int d30Count, int d60Count, int d60plusCount}) aging;
  const _AgingStrip({required this.aging});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aging Analysis',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              _AgingBucket('Current',    aging.current,  aging.cCount,     AppColors.success),
              _AgingDivider(),
              _AgingBucket('1–30 days',  aging.d30,     aging.d30Count,   AppColors.warning),
              _AgingDivider(),
              _AgingBucket('31–60 days', aging.d60,     aging.d60Count,   AppColors.orange),
              _AgingDivider(),
              _AgingBucket('60+ days',   aging.d60plus, aging.d60plusCount, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgingBucket extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  const _AgingBucket(this.label, this.amount, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            FerosNumberUtils.formatCurrencyCompact(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amount > 0 ? color : AppColors.mutedText,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count inv',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedText, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AgingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 36, color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}
