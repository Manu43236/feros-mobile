import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import '../../../../../core/utils/string_utils.dart';
import 'report_widgets.dart';

const _payrollStatusColors = {
  'DRAFT':    Color(0xFF64748B),
  'APPROVED': Color(0xFF2563EB),
  'PAID':     Color(0xFF16A34A),
};

class OfficeReportPayroll extends StatefulWidget {
  const OfficeReportPayroll({super.key});

  @override
  State<OfficeReportPayroll> createState() => _OfficeReportPayrollState();
}

class _OfficeReportPayrollState extends State<OfficeReportPayroll> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';
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
        ApiEndpoints.reportPayrollSummary,
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
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['userName'] as String? ?? '').toLowerCase().contains(q) ||
        (r['roleName'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalNet => _filtered.fold(0,
      (s, r) => s + ((r['netPay'] as num?) ?? 0).toDouble());
  double get _totalGross => _filtered.fold(0,
      (s, r) => s + ((r['grossPay'] as num?) ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Payroll Summary'),
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
              (label: 'Staff',     value: '${filtered.length}', color: null),
              (label: 'Total Net', value: FerosNumberUtils.formatCurrencyCompact(_totalNet), color: const Color(0xFF4ADE80)),
              (label: 'Gross',     value: FerosNumberUtils.formatCurrencyCompact(_totalGross), color: null),
            ]),
          ReportSearchBar(
            hint: 'Search staff name…',
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _PayrollRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PayrollRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _PayrollRow(this.r);

  @override
  Widget build(BuildContext context) {
    final name       = r['userName']         as String? ?? '—';
    final role       = r['roleName']         as String? ?? '';
    final net        = (r['netPay']          as num?)?.toDouble() ?? 0;
    final gross      = (r['grossPay']        as num?)?.toDouble() ?? 0;
    final deductions = (r['totalDeductions'] as num?)?.toDouble() ?? 0;
    final present    = r['presentDays']      as int? ?? 0;
    final total      = r['totalDays']        as int? ?? 0;
    final status     = r['payrollStatus']    as String? ?? '';

    final statusColor =
        _payrollStatusColors[status] ?? AppColors.mutedText;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0891B2).withValues(alpha: 0.1),
                child: Text(
                  FerosStringUtils.initials(name),
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF0891B2),
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(FerosStringUtils.roleLabel(role),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FerosNumberUtils.formatCurrency(net),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(status,
                        style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              _PayItem('Days', '$present / $total'),
              _PayItem('Gross', FerosNumberUtils.formatCurrencyCompact(gross)),
              _PayItem('Deductions',
                  FerosNumberUtils.formatCurrencyCompact(deductions),
                  color: deductions > 0 ? AppColors.error : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PayItem(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.bodyText)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText, fontSize: 10)),
        ],
      ),
    );
  }
}
