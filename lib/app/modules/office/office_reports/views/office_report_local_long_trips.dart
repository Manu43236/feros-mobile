import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportLocalLongTrips extends StatefulWidget {
  const OfficeReportLocalLongTrips({super.key});

  @override
  State<OfficeReportLocalLongTrips> createState() =>
      _OfficeReportLocalLongTripsState();
}

class _OfficeReportLocalLongTripsState
    extends State<OfficeReportLocalLongTrips> {
  final _api = Get.find<ApiClient>();

  bool _loading = true;
  Map<String, dynamic> _data = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportLocalLongTrips);
      setState(() {
        _data = (res.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>? ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTrips  = (_data['trips'] as List? ?? []).cast<Map<String, dynamic>>();
    final localCnt  = (_data['localCount']        as num?)?.toInt() ?? 0;
    final longCnt   = (_data['longDistanceCount'] as num?)?.toInt() ?? 0;
    final total     = (_data['totalToday']        as num?)?.toInt() ?? allTrips.length;

    final local    = allTrips.where((r) => r['tripType'] == 'LOCAL').toList();
    final longDist = allTrips.where((r) => r['tripType'] != 'LOCAL').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Local vs Long Trips'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppColors.navy,
                  child: ListView(
                    children: [
                      if (total > 0)
                        ReportSummaryStrip.items([
                          (label: 'Total Trips', value: '$total', color: null),
                          (label: 'Local', value: '$localCnt',
                              color: const Color(0xFF4ADE80)),
                          (label: 'Long Distance', value: '$longCnt',
                              color: const Color(0xFF60A5FA)),
                        ]),
                      if (total > 0) _TripTypeBar(localCnt: localCnt, longCnt: longCnt),
                      if (local.isNotEmpty) ...[
                        _SectionLabel('Local Trips ($localCnt)',
                            const Color(0xFF16A34A)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            children: local.map((r) => _TripRow(r, isLocal: true)).toList(),
                          ),
                        ),
                      ],
                      if (longDist.isNotEmpty) ...[
                        _SectionLabel('Long Distance Trips ($longCnt)',
                            const Color(0xFF2563EB)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            children: longDist.map((r) => _TripRow(r, isLocal: false)).toList(),
                          ),
                        ),
                      ],
                      if (total == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: ReportEmptyState(message: 'No trips today'),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _TripTypeBar extends StatelessWidget {
  final int localCnt;
  final int longCnt;
  const _TripTypeBar({required this.localCnt, required this.longCnt});

  @override
  Widget build(BuildContext context) {
    final total = localCnt + longCnt;
    if (total == 0) return const SizedBox();
    final localPct = localCnt / total;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Split today',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (localPct * 100).round(),
                  child: Container(height: 14, color: const Color(0xFF16A34A)),
                ),
                Expanded(
                  flex: ((1 - localPct) * 100).round().clamp(0, 100),
                  child: Container(height: 14, color: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(const Color(0xFF16A34A),
                  'Local ${(localPct * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 16),
              _LegendDot(const Color(0xFF2563EB),
                  'Long ${((1 - localPct) * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText, fontSize: 10)),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

class _TripRow extends StatelessWidget {
  final Map<String, dynamic> r;
  final bool isLocal;
  const _TripRow(this.r, {required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final lrNumber  = r['lrNumber']          as String? ?? '—';
    final vehicle   = r['registrationNumber'] as String? ?? '—';
    final client    = r['clientName']         as String? ?? '—';
    final fromCity  = r['fromCity']           as String? ?? '';
    final fromState = r['fromState']          as String? ?? '';
    final toCity    = r['toCity']             as String? ?? '';
    final toState   = r['toState']            as String? ?? '';
    final color     = isLocal ? const Color(0xFF16A34A) : const Color(0xFF2563EB);

    final from = [fromCity, fromState].where((s) => s.isNotEmpty).join(', ');
    final to   = [toCity,   toState  ].where((s) => s.isNotEmpty).join(', ');

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.local_shipping_outlined, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '# ',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 9),
                    ),
                    TextSpan(
                      text: lrNumber,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10),
                    ),
                  ]),
                ),
                const SizedBox(height: 2),
                Text(client,
                    style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
                if (from.isNotEmpty || to.isNotEmpty)
                  Text('$from → $to',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
