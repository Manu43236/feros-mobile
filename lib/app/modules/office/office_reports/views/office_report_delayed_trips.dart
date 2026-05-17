import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportDelayedTrips extends StatefulWidget {
  const OfficeReportDelayedTrips({super.key});

  @override
  State<OfficeReportDelayedTrips> createState() =>
      _OfficeReportDelayedTripsState();
}

class _OfficeReportDelayedTripsState extends State<OfficeReportDelayedTrips> {
  final _api = Get.find<ApiClient>();
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportDelayedTrips);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Sort most delayed first
      list.sort((a, b) => ((b['delayHours'] as num?) ?? 0)
          .compareTo((a['delayHours'] as num?) ?? 0));
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final severe = _data.where((r) =>
        ((r['delayHours'] as num?) ?? 0) > 24).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Delayed Trips'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _data.isEmpty
                  ? const ReportEmptyState(message: 'No delayed trips right now')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: Column(
                        children: [
                          ReportSummaryStrip.items([
                            (label: 'Delayed Trips', value: '${_data.length}',
                                color: AppColors.warning),
                            (label: 'Severe (>24h)', value: '$severe',
                                color: severe > 0
                                    ? const Color(0xFFFCA5A5)
                                    : null),
                          ]),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _DelayedTripRow(_data[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _DelayedTripRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _DelayedTripRow(this.r);

  @override
  Widget build(BuildContext context) {
    final lrNo    = r['lrNumber']      as String? ?? '—';
    final vehicle = r['vehicleNumber'] as String? ?? '—';
    final driver  = r['driverName']    as String? ?? '—';
    final route   = r['routeName']     as String? ?? '—';
    final hours   = (r['delayHours']   as num?)?.toDouble() ?? 0;
    final etd     = r['expectedDelivery'] as String?;

    final isSevere = hours > 24;
    final badgeColor = isSevere ? AppColors.error : AppColors.warning;
    final delayLabel = hours >= 24
        ? '${(hours / 24).toStringAsFixed(1)}d delay'
        : '${hours.toStringAsFixed(0)}h delay';

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
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(delayLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: badgeColor, fontWeight: FontWeight.w700,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(vehicle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(width: 12),
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(driver,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 4),
          Text(route,
              style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
          if (etd != null)
            Text('ETD: $etd',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText, fontSize: 10)),
        ],
      ),
    );
  }
}
