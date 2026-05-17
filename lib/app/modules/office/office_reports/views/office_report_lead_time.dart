import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportLeadTime extends StatefulWidget {
  const OfficeReportLeadTime({super.key});

  @override
  State<OfficeReportLeadTime> createState() => _OfficeReportLeadTimeState();
}

class _OfficeReportLeadTimeState extends State<OfficeReportLeadTime> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportOrderLeadTime,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = d['summary'] as Map<String, dynamic>? ?? {};
        _data    = (d['orders']  as List? ?? []).cast<Map<String, dynamic>>();
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

  @override
  Widget build(BuildContext context) {
    final avg    = (_summary['avgLeadTimeDays'] as num?)?.toDouble() ?? 0;
    final min    = (_summary['minLeadTimeDays'] as num?)?.toDouble() ?? 0;
    final max    = (_summary['maxLeadTimeDays'] as num?)?.toDouble() ?? 0;
    final total  = (_summary['totalOrders']     as num?)?.toInt() ?? _data.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        title: const Text('Lead Time'),
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
          if (!_loading && total > 0)
            ReportSummaryStrip.items([
              (label: 'Avg Lead Time',
                  value: '${avg.toStringAsFixed(1)} days', color: null),
              (label: 'Min', value: '${min.toStringAsFixed(1)}d', color: null),
              (label: 'Max', value: '${max.toStringAsFixed(1)}d', color: null),
              (label: 'Orders', value: '$total', color: null),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _LeadTimeRow(_data[i], avg),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _LeadTimeRow extends StatelessWidget {
  final Map<String, dynamic> r;
  final double avg;
  const _LeadTimeRow(this.r, this.avg);

  @override
  Widget build(BuildContext context) {
    final orderNo  = r['orderNumber']   as String? ?? '—';
    final client   = r['clientName']    as String? ?? '—';
    final days     = (r['leadTimeDays'] as num?)?.toDouble() ?? 0;
    final status   = r['status']        as String? ?? '—';

    final aboveAvg = avg > 0 && days > avg * 1.2;
    final color    = aboveAvg ? AppColors.error : AppColors.success;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
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
                        .copyWith(color: AppColors.mutedText)),
                Text(status,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${days.toStringAsFixed(1)} days',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700,
                      fontFamily: 'Inter', fontSize: 15)),
              if (aboveAvg)
                Text('above avg',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.error, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
