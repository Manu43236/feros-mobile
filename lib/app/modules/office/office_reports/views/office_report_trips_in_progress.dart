import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportTripsInProgress extends StatefulWidget {
  const OfficeReportTripsInProgress({super.key});

  @override
  State<OfficeReportTripsInProgress> createState() =>
      _OfficeReportTripsInProgressState();
}

class _OfficeReportTripsInProgressState
    extends State<OfficeReportTripsInProgress> {
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
      final res = await _api.get(ApiEndpoints.reportTripsInProgress);
      setState(() {
        _data = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) =>
        (r['lrNumber']       as String? ?? '').toLowerCase().contains(q) ||
        (r['vehicleNumber']  as String? ?? '').toLowerCase().contains(q) ||
        (r['driverName']     as String? ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Trips In Progress'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          if (!_loading && _data.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Active Trips', value: '${_data.length}', color: null),
            ]),
          ReportSearchBar(
            hint: 'Search LR#, vehicle, driver…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : filtered.isEmpty
                        ? const ReportEmptyState(message: 'No active trips right now')
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.navy,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _TripRow(filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _TripRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo    = r['lrNumber']      as String? ?? '—';
    final vehicle = r['vehicleNumber'] as String? ?? '—';
    final driver  = r['driverName']    as String? ?? '—';
    final from    = r['fromCity']      as String? ?? '—';
    final to      = r['toCity']        as String? ?? '—';
    final status  = r['status']        as String? ?? 'IN_TRANSIT';
    final since   = r['dispatchDate']  as String?;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lrNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED))),
              ),
              ReportStatusChip(
                status: status,
                colorMap: {
                  'IN_TRANSIT':  AppColors.warning,
                  'AT_CHECKPOST': AppColors.orange,
                  'NEAR_DEST':   AppColors.success,
                },
                labelMap: {
                  'IN_TRANSIT':  'In Transit',
                  'AT_CHECKPOST': 'At Checkpost',
                  'NEAR_DEST':   'Near Dest.',
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('$from → $to',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.bodyText, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(vehicle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(width: 10),
              const Icon(Icons.person_outline,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(driver,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              if (since != null) ...[
                const Spacer(),
                Text(_shortDate(since),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}';
    } catch (_) { return iso.length >= 10 ? iso.substring(5, 10) : iso; }
  }
}
