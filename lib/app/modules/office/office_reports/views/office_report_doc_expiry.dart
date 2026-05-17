import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

const _daysOptions = [30, 60, 90];

class OfficeReportDocExpiry extends StatefulWidget {
  const OfficeReportDocExpiry({super.key});

  @override
  State<OfficeReportDocExpiry> createState() => _OfficeReportDocExpiryState();
}

class _OfficeReportDocExpiryState extends State<OfficeReportDocExpiry> {
  final _api = Get.find<ApiClient>();

  int _daysAhead = 30;
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportDocExpiry,
        params: {'daysAhead': '$_daysAhead'},
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

  int get _expiredCount =>
      _data.where((r) => ((r['daysUntilExpiry'] as num?) ?? 1) <= 0).length;
  int get _criticalCount =>
      _data.where((r) {
        final d = (r['daysUntilExpiry'] as num?)?.toInt() ?? 999;
        return d > 0 && d <= 7;
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Document Expiry'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          _DaysFilter(
            selected: _daysAhead,
            onSelect: (d) { setState(() => _daysAhead = d); _fetch(); },
          ),
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Expiring Soon', value: '${_data.length}', color: null),
              (label: 'Expired', value: '$_expiredCount',
                  color: _expiredCount > 0 ? const Color(0xFFFCA5A5) : null),
              (label: 'Critical (≤7d)', value: '$_criticalCount',
                  color: _criticalCount > 0 ? AppColors.warning : null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? ReportEmptyState(
                            message: 'No documents expiring in $_daysAhead days')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _DocExpiryRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DaysFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _DaysFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Text('Expiring in:',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(width: 10),
          ..._daysOptions.map((d) {
            final sel = d == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.navy : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.navy : AppColors.border),
                  ),
                  child: Text('${d}d',
                      style: AppTextStyles.caption.copyWith(
                          color: sel ? Colors.white : AppColors.bodyText,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DocExpiryRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _DocExpiryRow(this.r);

  @override
  Widget build(BuildContext context) {
    final entity   = r['entityName']      as String? ?? '—';
    final type     = r['entityType']      as String? ?? '—';
    final docType  = r['documentType']    as String? ?? '—';
    final expDate  = r['expiryDate']      as String? ?? '—';
    final days     = (r['daysUntilExpiry'] as num?)?.toInt() ?? 0;

    final isExpired  = days <= 0;
    final isCritical = !isExpired && days <= 7;
    final badgeColor = isExpired
        ? AppColors.error
        : isCritical
            ? AppColors.warning
            : AppColors.orange;

    final badgeLabel = isExpired
        ? 'EXPIRED'
        : '${days}d left';

    final entityColor = type == 'VEHICLE'
        ? const Color(0xFF0284C7)
        : AppColors.orange;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: entityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              type == 'VEHICLE'
                  ? Icons.directions_bus_outlined
                  : Icons.badge_outlined,
              size: 18, color: entityColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entity,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(docType,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                Text('Expires $expDate',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
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
            child: Text(badgeLabel,
                style: AppTextStyles.caption.copyWith(
                    color: badgeColor, fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
