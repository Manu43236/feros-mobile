import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

const _lrStatusColors = {
  'CREATED':    Color(0xFF2563EB),
  'LOADED':     Color(0xFF7C3AED),
  'IN_TRANSIT': Color(0xFFF97316),
  'DELIVERED':  Color(0xFF16A34A),
  'INVOICED':   Color(0xFF64748B),
};
const _lrStatusLabels = {
  'CREATED':    'Created',
  'LOADED':     'Loaded',
  'IN_TRANSIT': 'In Transit',
  'DELIVERED':  'Delivered',
  'INVOICED':   'Invoiced',
};

class OfficeReportLrRegister extends StatefulWidget {
  const OfficeReportLrRegister({super.key});

  @override
  State<OfficeReportLrRegister> createState() =>
      _OfficeReportLrRegisterState();
}

class _OfficeReportLrRegisterState extends State<OfficeReportLrRegister> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';
  String _statusFilter = 'ALL';
  String _search = '';

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
        ApiEndpoints.reportLrRegister,
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

  List<Map<String, dynamic>> get _filtered {
    var list = _statusFilter == 'ALL'
        ? _data
        : _data.where((r) => r['lrStatus'] == _statusFilter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) =>
          (r['lrNumber'] as String? ?? '').toLowerCase().contains(q) ||
          (r['clientName'] as String? ?? '').toLowerCase().contains(q) ||
          (r['vehicleRegistrationNumber'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  double get _totalWeight => _filtered.fold(0,
      (s, r) => s + ((r['loadedWeight'] as num?) ?? 0).toDouble());

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
        title: const Text('LR Register'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          ReportDateBar(
            from: _from, to: _to, preset: _preset,
            onPreset: _setPreset,
            onPickFrom: _pickFrom, onPickTo: _pickTo,
          ),
          // Status filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'CREATED', 'LOADED', 'IN_TRANSIT',
                           'DELIVERED', 'INVOICED'].map((s) {
                  final sel = _statusFilter == s;
                  final color = s == 'ALL'
                      ? AppColors.navy
                      : (_lrStatusColors[s] ?? AppColors.mutedText);
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
                        child: Text(
                          s == 'ALL' ? 'All' : (_lrStatusLabels[s] ?? s),
                          style: AppTextStyles.caption.copyWith(
                            color: sel ? color : AppColors.mutedText,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'LRs',    value: '${filtered.length}', color: null),
              (label: 'Weight', value: '${_totalWeight.toStringAsFixed(1)} T', color: null),
            ]),
          ReportSearchBar(
            hint: 'Search LR#, client, vehicle…',
            onChanged: (v) => setState(() => _search = v),
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
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _LrRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _LrRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _LrRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo   = r['lrNumber']                  as String? ?? '—';
    final client = r['clientName']                 as String? ?? '—';
    final from   = r['fromCity']                   as String? ?? '';
    final to     = r['toCity']                     as String? ?? '';
    final status = r['lrStatus']                   as String? ?? '';
    final weight = (r['loadedWeight'] as num?)?.toDouble();
    final date   = r['lrDate']                     as String?;
    final vehicle= r['vehicleRegistrationNumber']  as String? ?? '—';

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lrNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              ReportStatusChip(
                status: status,
                colorMap: _lrStatusColors,
                labelMap: _lrStatusLabels,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 12, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(client,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.bodyText)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.route_outlined,
                  size: 12, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('$from → $to',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(vehicle,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (weight != null)
                Text(FerosNumberUtils.formatWeight(weight),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.bodyText,
                        fontWeight: FontWeight.w600)),
              if (date != null) ...[
                const SizedBox(width: 10),
                Text(date.length >= 10 ? date.substring(0, 10) : date,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
