import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportPendingBilling extends StatefulWidget {
  const OfficeReportPendingBilling({super.key});

  @override
  State<OfficeReportPendingBilling> createState() =>
      _OfficeReportPendingBillingState();
}

class _OfficeReportPendingBillingState
    extends State<OfficeReportPendingBilling> {
  final _api = Get.find<ApiClient>();
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;
  String _search = '';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportClientPendingBilling);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['pendingLrCount'] as num?) ?? 0)
          .compareTo((a['pendingLrCount'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['clientName'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalValue => _filtered.fold(
      0.0, (s, r) => s + ((r['totalFreight'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Pending Billing'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Clients', value: '${_data.length}', color: null),
              (label: 'Pending Value',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalValue),
                  color: AppColors.warning),
            ]),
          ReportSearchBar(
            hint: 'Search client…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState(
                            message: 'No clients with pending billing')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _PendingClientRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PendingClientRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _PendingClientRow(this.r);

  @override
  Widget build(BuildContext context) {
    final client   = r['clientName']       as String? ?? '—';
    final lrCount  = (r['pendingLrCount']  as num?)?.toInt() ?? 0;
    final freight  = (r['totalFreight']    as num?)?.toDouble() ?? 0;
    final oldest   = r['oldestLrDate']     as String?;
    final daysSince = oldest != null ? _daysSince(oldest) : null;

    final isOld = daysSince != null && daysSince > 7;
    final badgeColor = isOld ? AppColors.error : AppColors.warning;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_outlined,
                size: 20, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$lrCount LR${lrCount != 1 ? 's' : ''} awaiting invoice',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (daysSince != null)
                  Text('Oldest: ${daysSince}d ago',
                      style: AppTextStyles.caption.copyWith(
                          color: badgeColor, fontSize: 10,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(FerosNumberUtils.formatCurrencyCompact(freight),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.bodyText)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text('$lrCount LRs',
                    style: AppTextStyles.caption.copyWith(
                        color: badgeColor, fontWeight: FontWeight.w600,
                        fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _daysSince(String iso) {
    try {
      return DateTime.now().difference(DateTime.parse(iso)).inDays;
    } catch (_) { return 0; }
  }
}
