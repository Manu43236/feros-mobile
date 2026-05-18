import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportLrFunnel extends StatefulWidget {
  const OfficeReportLrFunnel({super.key});

  @override
  State<OfficeReportLrFunnel> createState() => _OfficeReportLrFunnelState();
}

class _OfficeReportLrFunnelState extends State<OfficeReportLrFunnel> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  List<Map<String, dynamic>> _stages = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportLrStatusFunnel,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
      );
      final d = (res.data as Map?)?['data'];
      setState(() {
        if (d is List) {
          _stages = d.cast<Map<String, dynamic>>();
        } else if (d is Map) {
          _stages = (d['stages'] as List? ?? []).cast<Map<String, dynamic>>();
        }
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

  static const _stageColors = {
    'CREATED':      Color(0xFF6366F1),
    'DISPATCHED':   Color(0xFF0284C7),
    'IN_TRANSIT':   Color(0xFFF59E0B),
    'DELIVERED':    Color(0xFF10B981),
    'BILLED':       Color(0xFF059669),
    'PAID':         Color(0xFF16A34A),
  };

  @override
  Widget build(BuildContext context) {
    final total = _stages.isNotEmpty
        ? ((_stages.first['count'] as num?)?.toInt() ?? 0)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('LR Status Funnel'),
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
                    : _stages.isEmpty
                        ? const ReportEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              children: [
                                Text('LR flow — how many reach each stage',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.mutedText)),
                                const SizedBox(height: 16),
                                ..._stages.asMap().entries.map((e) {
                                  final stage = e.value;
                                  final label = stage['status'] as String? ?? '—';
                                  final count = (stage['count'] as num?)?.toInt() ?? 0;
                                  final pct = total > 0 ? count / total : 0.0;
                                  final color = _stageColors[label]
                                      ?? const Color(0xFF7C3AED);
                                  return _FunnelRow(
                                    label: label,
                                    count: count,
                                    pct: pct,
                                    color: color,
                                    isLast: e.key == _stages.length - 1,
                                  );
                                }),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  final bool isLast;
  const _FunnelRow({
    required this.label,
    required this.count,
    required this.pct,
    required this.color,
    required this.isLast,
  });

  static const _labels = {
    'CREATED':    'Created',
    'DISPATCHED': 'Dispatched',
    'IN_TRANSIT': 'In Transit',
    'DELIVERED':  'Delivered',
    'BILLED':     'Billed',
    'PAID':       'Paid',
  };

  @override
  Widget build(BuildContext context) {
    final displayLabel = _labels[label] ?? label;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(displayLabel,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Text('$count',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800,
                          fontFamily: 'Inter', fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.keyboard_arrow_down,
                color: AppColors.mutedText.withValues(alpha: 0.5), size: 20),
          ),
      ],
    );
  }
}
