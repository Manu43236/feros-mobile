import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportOrdersBacklog extends StatefulWidget {
  const OfficeReportOrdersBacklog({super.key});

  @override
  State<OfficeReportOrdersBacklog> createState() =>
      _OfficeReportOrdersBacklogState();
}

class _OfficeReportOrdersBacklogState
    extends State<OfficeReportOrdersBacklog> {
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
      final res = await _api.get(ApiEndpoints.reportOrdersBacklog);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['pendingDays'] as num?) ?? 0)
          .compareTo((a['pendingDays'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['orderNumber']  as String? ?? '').toLowerCase().contains(q) ||
        (r['clientName']   as String? ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final old = filtered.where((r) =>
        ((r['pendingDays'] as num?) ?? 0) > 3).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Orders Backlog'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Unassigned', value: '${_data.length}', color: null),
              (label: 'Waiting >3 days', value: '$old',
                  color: old > 0 ? const Color(0xFFFCA5A5) : null),
            ]),
          ReportSearchBar(
            hint: 'Search order#, client…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState(
                            message: 'No unassigned orders')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _BacklogRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _BacklogRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _BacklogRow(this.r);

  @override
  Widget build(BuildContext context) {
    final orderNo  = r['orderNumber']  as String? ?? '—';
    final client   = r['clientName']   as String? ?? '—';
    final route    = r['routeName']    as String?;
    final days     = (r['pendingDays'] as num?)?.toInt() ?? 0;
    final lrCount  = (r['lrCount']     as num?)?.toInt() ?? 0;

    final isOld = days > 3;
    final badgeColor = isOld ? AppColors.error : AppColors.warning;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inbox_outlined, size: 18,
                color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(client,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.bodyText)),
                if (route != null)
                  Text(route,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                if (lrCount > 0)
                  Text('$lrCount LR${lrCount != 1 ? 's' : ''}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Text('${days}d waiting',
                style: AppTextStyles.caption.copyWith(
                    color: badgeColor, fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
