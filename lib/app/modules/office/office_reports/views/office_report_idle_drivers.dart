import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportIdleDrivers extends StatefulWidget {
  const OfficeReportIdleDrivers({super.key});

  @override
  State<OfficeReportIdleDrivers> createState() =>
      _OfficeReportIdleDriversState();
}

class _OfficeReportIdleDriversState extends State<OfficeReportIdleDrivers> {
  final _api = Get.find<ApiClient>();
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportIdleDrivers);
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
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Idle Drivers'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _data.isEmpty
                  ? const ReportEmptyState(message: 'No idle drivers — everyone is assigned')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: Column(
                        children: [
                          ReportSummaryStrip.items([
                            (label: 'Idle Drivers', value: '${_data.length}',
                                color: const Color(0xFFFCA5A5)),
                          ]),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _data.length,
                              itemBuilder: (_, i) => _IdleDriverRow(_data[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _IdleDriverRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _IdleDriverRow(this.r);

  @override
  Widget build(BuildContext context) {
    final name        = r['driverName']    as String? ?? '—';
    final phone       = r['phone']         as String?;
    final idleSince   = r['idleSince']     as String?;
    final lastTrip    = r['lastTripDate']  as String?;
    final designation = r['designation']   as String? ?? 'Driver';

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(Icons.person_outline, size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(designation,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                if (phone != null)
                  Text(phone,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (idleSince != null)
                Text('Idle since',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 10)),
              if (idleSince != null)
                Text(_shortDate(idleSince),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              if (lastTrip != null) ...[
                const SizedBox(height: 4),
                Text('Last trip ${_shortDate(lastTrip)}',
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
    } catch (_) { return iso.length > 10 ? iso.substring(5, 10) : iso; }
  }
}
