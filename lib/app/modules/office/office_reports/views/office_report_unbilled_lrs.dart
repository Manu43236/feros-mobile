import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportUnbilledLrs extends StatefulWidget {
  const OfficeReportUnbilledLrs({super.key});

  @override
  State<OfficeReportUnbilledLrs> createState() =>
      _OfficeReportUnbilledLrsState();
}

class _OfficeReportUnbilledLrsState extends State<OfficeReportUnbilledLrs> {
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
      final res = await _api.get(ApiEndpoints.reportUnbilledLrs);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['daysUnbilled'] as num?) ?? 0)
          .compareTo((a['daysUnbilled'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['lrNumber']   as String? ?? '').toLowerCase().contains(q) ||
        (r['clientName'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalFreight => _filtered.fold(
      0, (s, r) => s + ((r['freightAmount'] as num?) ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final overdue  = filtered.where((r) =>
        ((r['daysUnbilled'] as num?) ?? 0) > 7).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Unbilled LRs'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Unbilled LRs', value: '${_data.length}', color: null),
              (label: '>7 days', value: '$overdue',
                  color: overdue > 0 ? const Color(0xFFFCA5A5) : null),
              (label: 'Freight Value',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalFreight),
                  color: null),
            ]),
          ReportSearchBar(
            hint: 'Search LR#, client…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState(message: 'No unbilled LRs')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _UnbilledLrRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _UnbilledLrRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _UnbilledLrRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo    = r['lrNumber']      as String? ?? '—';
    final client  = r['clientName']    as String? ?? '—';
    final route   = r['routeName']     as String?;
    final freight = (r['freightAmount'] as num?)?.toDouble() ?? 0;
    final days    = (r['daysUnbilled']  as num?)?.toInt() ?? 0;
    final delDate = r['deliveryDate']   as String?;

    final isLate  = days > 7;
    final color   = isLate ? AppColors.error : AppColors.warning;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 18,
                color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lrNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED))),
                const SizedBox(height: 2),
                Text(client,
                    style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
                if (route != null)
                  Text(route,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                if (delDate != null)
                  Text('Delivered: $delDate',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text('${days}d unbilled',
                    style: AppTextStyles.caption.copyWith(
                        color: color, fontWeight: FontWeight.w600, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
