import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportDailyActivity extends StatefulWidget {
  const OfficeReportDailyActivity({super.key});

  @override
  State<OfficeReportDailyActivity> createState() =>
      _OfficeReportDailyActivityState();
}

class _OfficeReportDailyActivityState
    extends State<OfficeReportDailyActivity> {
  final _api = Get.find<ApiClient>();

  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(ApiEndpoints.reportDailyVehicles);
      setState(() {
        _data = (res.data as Map)['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _rows(String key) {
    if (_data == null) return [];
    return ((_data![key] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final onRoad      = _data?['onRoadCount']       as int? ?? 0;
    final started     = _data?['startedTodayCount']  as int? ?? 0;
    final delivered   = _data?['deliveredTodayCount'] as int? ?? 0;
    final idle        = _data?['idleCount']           as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Fleet Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          )
        ],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _data == null
                  ? const ReportEmptyState(message: 'No fleet data available')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: CustomScrollView(
                        slivers: [
                          // Summary strip
                          SliverToBoxAdapter(
                            child: ReportSummaryStrip.items([
                              (label: 'On Road',   value: '$onRoad',    color: null),
                              (label: 'Started',   value: '$started',   color: null),
                              (label: 'Delivered', value: '$delivered', color: const Color(0xFF4ADE80)),
                              (label: 'Idle',      value: '$idle',      color: Colors.white70),
                            ]),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (_rows('onRoad').isNotEmpty) ...[
                                  _SectionHeader('ON ROAD', onRoad, AppColors.navy),
                                  ..._rows('onRoad').map((v) => _VehicleRow(v, 'ON ROAD')),
                                  const SizedBox(height: 8),
                                ],
                                if (_rows('startedToday').isNotEmpty) ...[
                                  _SectionHeader('STARTED TODAY', started, AppColors.orange),
                                  ..._rows('startedToday').map((v) => _VehicleRow(v, 'STARTED')),
                                  const SizedBox(height: 8),
                                ],
                                if (_rows('deliveredToday').isNotEmpty) ...[
                                  _SectionHeader('DELIVERED TODAY', delivered, AppColors.success),
                                  ..._rows('deliveredToday').map((v) => _VehicleRow(v, 'DELIVERED')),
                                  const SizedBox(height: 8),
                                ],
                                if (_rows('idle').isNotEmpty) ...[
                                  _SectionHeader('IDLE', idle, AppColors.mutedText),
                                  ..._rows('idle').map((v) => _VehicleRow(v, 'IDLE')),
                                ],
                                if (_rows('onRoad').isEmpty &&
                                    _rows('startedToday').isEmpty &&
                                    _rows('deliveredToday').isEmpty &&
                                    _rows('idle').isEmpty)
                                  const ReportEmptyState(message: 'No vehicle activity today'),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: color,
              margin: const EdgeInsets.only(right: 8)),
          Text(title,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final Map<String, dynamic> v;
  final String status;
  const _VehicleRow(this.v, this.status);

  @override
  Widget build(BuildContext context) {
    final reg    = v['registrationNumber'] as String? ?? '—';
    final client = v['clientName']         as String? ?? '—';
    final from   = v['fromCity']           as String? ?? '';
    final to     = v['toCity']             as String? ?? '';
    final lrNo   = v['lrNumber']           as String?;
    final time   = status == 'DELIVERED'
        ? v['deliveredAt'] as String?
        : v['loadedAt'] as String?;

    return ReportCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bus_outlined,
                size: 20, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                if (from.isNotEmpty && to.isNotEmpty)
                  Text('$from → $to',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                Text(client,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.bodyText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lrNo != null)
                Text(lrNo,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy, fontWeight: FontWeight.w600)),
              if (time != null)
                Text(time.length > 10 ? time.substring(11, 16) : time,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
            ],
          ),
        ],
      ),
    );
  }
}
