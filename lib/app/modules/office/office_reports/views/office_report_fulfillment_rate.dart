import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportFulfillmentRate extends StatefulWidget {
  const OfficeReportFulfillmentRate({super.key});

  @override
  State<OfficeReportFulfillmentRate> createState() =>
      _OfficeReportFulfillmentRateState();
}

class _OfficeReportFulfillmentRateState
    extends State<OfficeReportFulfillmentRate> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _routes = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportOrderFulfillment,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? d;
        _routes  = (d['byRoute'] as List? ?? []).cast<Map<String, dynamic>>();
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

  @override
  Widget build(BuildContext context) {
    final total     = (_summary['totalOrders']     as num?)?.toInt() ?? 0;
    final completed = (_summary['completedOrders'] as num?)?.toInt() ?? 0;
    final onTime    = (_summary['onTimeOrders']    as num?)?.toInt() ?? 0;
    final cancelled = (_summary['cancelledOrders'] as num?)?.toInt() ?? 0;
    final fulfillPct = total > 0 ? (completed / total * 100) : 0.0;
    final onTimePct  = completed > 0 ? (onTime / completed * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Fulfillment Rate'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset, onPickFrom: _pickFrom, onPickTo: _pickTo,
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
                            // Big stat tiles
                            Row(children: [
                              _StatTile('Fulfillment Rate',
                                  '${fulfillPct.toStringAsFixed(1)}%',
                                  fulfillPct >= 90
                                      ? AppColors.success
                                      : fulfillPct >= 70
                                          ? AppColors.warning
                                          : AppColors.error),
                              const SizedBox(width: 12),
                              _StatTile('On-Time Rate',
                                  '${onTimePct.toStringAsFixed(1)}%',
                                  onTimePct >= 90
                                      ? AppColors.success
                                      : onTimePct >= 70
                                          ? AppColors.warning
                                          : AppColors.error),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              _StatTile('Total Orders', '$total', AppColors.navy),
                              const SizedBox(width: 12),
                              _StatTile('Cancelled', '$cancelled',
                                  cancelled > 0 ? AppColors.error : AppColors.mutedText),
                            ]),
                            if (_routes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('By Route',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.mutedText,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4)),
                              const SizedBox(height: 8),
                              ..._routes.map((r) => _RouteRow(r)),
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x07000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: color, fontFamily: 'Inter')),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _RouteRow(this.r);

  @override
  Widget build(BuildContext context) {
    final route    = r['routeName']   as String? ?? '—';
    final total    = (r['total']      as num?)?.toInt() ?? 0;
    final done     = (r['completed']  as num?)?.toInt() ?? 0;
    final pct      = total > 0 ? done / total : 0.0;
    final color    = pct >= 0.9 ? AppColors.success
        : pct >= 0.7 ? AppColors.warning : AppColors.error;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(route,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('$done of $total orders completed',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
