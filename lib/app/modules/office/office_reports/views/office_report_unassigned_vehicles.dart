import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportUnassignedVehicles extends StatefulWidget {
  const OfficeReportUnassignedVehicles({super.key});

  @override
  State<OfficeReportUnassignedVehicles> createState() =>
      _OfficeReportUnassignedVehiclesState();
}

class _OfficeReportUnassignedVehiclesState
    extends State<OfficeReportUnassignedVehicles> {
  final _api = Get.find<ApiClient>();
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportUnassignedVehicles);
      setState(() {
        _data = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        title: const Text('Unassigned Vehicles'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _data.isEmpty
                  ? const ReportEmptyState(
                      message: 'All vehicles are currently assigned')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: Column(
                        children: [
                          ReportSummaryStrip.items([
                            (label: 'Unassigned', value: '${_data.length}',
                                color: AppColors.warning),
                          ]),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) =>
                                  _VehicleRow(_data[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _VehicleRow(this.r);

  @override
  Widget build(BuildContext context) {
    final regNo     = r['vehicleNumber']    as String? ?? '—';
    final type      = r['vehicleType']      as String? ?? '—';
    final status    = r['status']           as String? ?? '—';
    final lastTrip  = r['lastTripDate']     as String?;
    final location  = r['currentLocation']  as String?;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 20, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regNo,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(type,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (location != null)
                  Text(location,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10)),
                if (lastTrip != null)
                  Text('Last trip: $lastTrip',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          ReportStatusChip(
            status: status,
            colorMap: {
              'AVAILABLE': AppColors.success,
              'MAINTENANCE': AppColors.error,
              'IDLE': AppColors.warning,
            },
          ),
        ],
      ),
    );
  }
}
