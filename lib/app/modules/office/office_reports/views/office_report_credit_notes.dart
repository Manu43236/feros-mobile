import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportCreditNotes extends StatefulWidget {
  const OfficeReportCreditNotes({super.key});

  @override
  State<OfficeReportCreditNotes> createState() =>
      _OfficeReportCreditNotesState();
}

class _OfficeReportCreditNotesState extends State<OfficeReportCreditNotes> {
  final _api = Get.find<ApiClient>();

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime.now();
  String _preset = 'month';

  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportCreditNotesReport,
        params: {'from': fmtApiDate(_from), 'to': fmtApiDate(_to)},
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

  double get _totalAmount => _data.fold(
      0.0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text('Credit Notes'),
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
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Credit Notes', value: '${_data.length}', color: null),
              (label: 'Total Value',
                  value: FerosNumberUtils.formatCurrencyCompact(_totalAmount),
                  color: const Color(0xFFFCA5A5)),
            ]),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _data.isEmpty
                        ? const ReportEmptyState(
                            message: 'No credit notes in this period')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _CreditNoteRow(_data[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CreditNoteRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _CreditNoteRow(this.r);

  @override
  Widget build(BuildContext context) {
    final cnNo    = r['creditNoteNumber'] as String? ?? '—';
    final client  = r['clientName']       as String? ?? '—';
    final amount  = (r['amount']          as num?)?.toDouble() ?? 0;
    final reason  = r['reason']           as String?;
    final date    = r['date']             as String?;
    final status  = r['status']           as String? ?? '—';

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.discount_outlined, size: 18,
                color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cnNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(client,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (reason != null)
                  Text(reason,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                if (date != null)
                  Text(date.length >= 10 ? date.substring(0, 10) : date,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(FerosNumberUtils.formatCurrencyCompact(amount),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.error)),
              const SizedBox(height: 4),
              ReportStatusChip(
                status: status,
                colorMap: {
                  'APPROVED': AppColors.success,
                  'PENDING':  AppColors.warning,
                  'REJECTED': AppColors.error,
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
