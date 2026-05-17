import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

const _orderStatusColors = {
  'PENDING':             Color(0xFFF59E0B),
  'PARTIALLY_ASSIGNED':  Color(0xFF2563EB),
  'FULLY_ASSIGNED':      Color(0xFF7C3AED),
  'IN_TRANSIT':          Color(0xFFF97316),
  'PARTIALLY_DELIVERED': Color(0xFF0891B2),
  'DELIVERED':           Color(0xFF16A34A),
  'COMPLETED':           Color(0xFF16A34A),
  'CANCELLED':           Color(0xFFDC2626),
};
const _orderStatusLabels = {
  'PENDING':             'Pending',
  'PARTIALLY_ASSIGNED':  'Part Assigned',
  'FULLY_ASSIGNED':      'Assigned',
  'IN_TRANSIT':          'In Transit',
  'PARTIALLY_DELIVERED': 'Part Delivered',
  'DELIVERED':           'Delivered',
  'COMPLETED':           'Completed',
  'CANCELLED':           'Cancelled',
};
const _paymentColors = {
  'UNPAID':       Color(0xFFDC2626),
  'PARTIALLY_PAID': Color(0xFFF59E0B),
  'PAID':         Color(0xFF16A34A),
};

const _statusFilterOptions = [
  'ALL', 'PENDING', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED', 'CANCELLED'
];

class OfficeReportOrderStatus extends StatefulWidget {
  const OfficeReportOrderStatus({super.key});

  @override
  State<OfficeReportOrderStatus> createState() =>
      _OfficeReportOrderStatusState();
}

class _OfficeReportOrderStatusState extends State<OfficeReportOrderStatus> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';
  String _statusFilter = 'ALL';

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportOrderStatus,
        params: {
          'from': fmtApiDate(_from),
          'to':   fmtApiDate(_to),
        },
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

  void _setPreset(String p) {
    if (p == 'custom') { setState(() => _preset = 'custom'); return; }
    final (f, t) = presetDates(p);
    setState(() { _from = f; _to = t; _preset = p; });
    _fetch();
  }

  Future<void> _pickFrom() async {
    final d = await pickDate(context, initial: _from, last: _to);
    if (d != null) { setState(() { _from = d; _preset = 'custom'; }); _fetch(); }
  }

  Future<void> _pickTo() async {
    final d = await pickDate(context, initial: _to, first: _from);
    if (d != null) { setState(() { _to = d; _preset = 'custom'; }); _fetch(); }
  }

  List<Map<String, dynamic>> get _filtered => _statusFilter == 'ALL'
      ? _data
      : _data
          .where((r) => (r['orderStatus'] as String? ?? '') == _statusFilter)
          .toList();

  Map<String, int> get _counts {
    final m = <String, int>{};
    for (final r in _data) {
      final s = r['orderStatus'] as String? ?? 'UNKNOWN';
      m[s] = (m[s] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final counts = _counts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Order Status'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset,
            onPickFrom: _pickFrom, onPickTo: _pickTo,
          ),
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Total',     value: '${_data.length}',           color: null),
              (label: 'Pending',   value: '${counts['PENDING'] ?? 0}', color: const Color(0xFFFCD34D)),
              (label: 'Active',    value: '${(counts['IN_TRANSIT'] ?? 0) + (counts['FULLY_ASSIGNED'] ?? 0)}', color: null),
              (label: 'Done',      value: '${(counts['COMPLETED'] ?? 0) + (counts['DELIVERED'] ?? 0)}', color: const Color(0xFF4ADE80)),
            ]),
          // Status filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilterOptions.map((s) {
                  final sel   = _statusFilter == s;
                  final color = s == 'ALL'
                      ? AppColors.navy
                      : (_orderStatusColors[s] ?? AppColors.mutedText);
                  final label = s == 'ALL' ? 'All' : (_orderStatusLabels[s] ?? s);
                  final cnt   = s == 'ALL' ? _data.length : (counts[s] ?? 0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: sel ? color : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label,
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      sel ? color : AppColors.mutedText,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                )),
                            const SizedBox(width: 4),
                            Text('$cnt',
                                style: AppTextStyles.caption.copyWith(
                                  color: sel
                                      ? color
                                      : AppColors.mutedText,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _OrderRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _OrderRow(this.r);

  @override
  Widget build(BuildContext context) {
    final orderNo  = r['orderNumber']        as String? ?? '—';
    final client   = r['clientName']         as String? ?? '—';
    final from     = r['fromCity']           as String? ?? '';
    final to       = r['toCity']             as String? ?? '';
    final status   = r['orderStatus']        as String? ?? '';
    final payment  = r['orderPaymentStatus'] as String? ?? '';
    final weight   = (r['totalWeight'] as num?)?.toDouble();
    final freight  = (r['totalFreightAmount'] as num?)?.toDouble();

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(orderNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              ReportStatusChip(
                  status: status,
                  colorMap: _orderStatusColors,
                  labelMap: _orderStatusLabels),
              const SizedBox(width: 6),
              ReportStatusChip(
                  status: payment,
                  colorMap: _paymentColors),
            ],
          ),
          const SizedBox(height: 5),
          Text(client,
              style:
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.route_outlined,
                  size: 12, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('$from → $to',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
              const Spacer(),
              if (weight != null)
                Text(FerosNumberUtils.formatWeight(weight),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.bodyText,
                        fontWeight: FontWeight.w600)),
              if (freight != null) ...[
                const SizedBox(width: 8),
                Text(FerosNumberUtils.formatCurrencyCompact(freight),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
