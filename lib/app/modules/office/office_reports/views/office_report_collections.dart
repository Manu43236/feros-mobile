import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

const _modeColors = {
  'CASH':  Color(0xFF16A34A),
  'CHEQUE': Color(0xFF7C3AED),
  'NEFT':  Color(0xFF2563EB),
  'RTGS':  Color(0xFF0891B2),
  'UPI':   Color(0xFFF97316),
};

class OfficeReportCollections extends StatefulWidget {
  const OfficeReportCollections({super.key});

  @override
  State<OfficeReportCollections> createState() =>
      _OfficeReportCollectionsState();
}

class _OfficeReportCollectionsState extends State<OfficeReportCollections> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

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
        ApiEndpoints.reportCollections,
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

  double get _total =>
      _data.fold(0, (s, r) => s + ((r['amount'] as num?) ?? 0).toDouble());

  Map<String, double> get _modeBreakdown {
    final m = <String, double>{};
    for (final r in _data) {
      final mode   = r['paymentMode'] as String? ?? 'OTHER';
      final amount = (r['amount'] as num?)?.toDouble() ?? 0;
      m[mode] = (m[mode] ?? 0) + amount;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Collections'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset,
            onPickFrom: _pickFrom, onPickTo: _pickTo,
          ),
          if (!_loading && _data.isNotEmpty) ...[
            ReportSummaryStrip.items([
              (
                label: 'Total Collected',
                value: FerosNumberUtils.formatCurrencyCompact(_total),
                color: const Color(0xFF4ADE80),
              ),
              (
                label: 'Payments',
                value: '${_data.length}',
                color: null,
              ),
            ]),
            _ModeBreakdown(breakdown: _modeBreakdown, colors: _modeColors),
          ],
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _data.length,
                              itemBuilder: (_, i) =>
                                  _CollectionRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _CollectionRow(this.r);

  @override
  Widget build(BuildContext context) {
    final date   = r['paymentDate']    as String? ?? '—';
    final client = r['clientName']     as String? ?? '—';
    final invNo  = r['invoiceNumber']  as String? ?? '—';
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    final mode   = r['paymentMode']    as String? ?? '—';
    final ref    = r['referenceNumber'] as String?;

    final modeColor = _modeColors[mode] ?? AppColors.mutedText;

    return ReportCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_outlined,
                size: 20, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$invNo  ·  $date',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (ref != null && ref.isNotEmpty)
                  Text('Ref: $ref',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FerosNumberUtils.formatCurrency(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.success),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: modeColor.withValues(alpha: 0.3)),
                ),
                child: Text(mode,
                    style: AppTextStyles.caption.copyWith(
                        color: modeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payment mode breakdown strip ──────────────────────────────────────────────

class _ModeBreakdown extends StatelessWidget {
  final Map<String, double> breakdown;
  final Map<String, Color> colors;
  const _ModeBreakdown({required this.breakdown, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox();
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Payment Mode',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sorted.map((e) {
                final color = colors[e.key] ?? AppColors.mutedText;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key,
                            style: AppTextStyles.caption.copyWith(
                                color: color, fontWeight: FontWeight.w700,
                                fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          FerosNumberUtils.formatCurrencyCompact(e.value),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
