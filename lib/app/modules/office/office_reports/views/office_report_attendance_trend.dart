import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportAttendanceTrend extends StatefulWidget {
  const OfficeReportAttendanceTrend({super.key});

  @override
  State<OfficeReportAttendanceTrend> createState() =>
      _OfficeReportAttendanceTrendState();
}

class _OfficeReportAttendanceTrendState
    extends State<OfficeReportAttendanceTrend> {
  final _api = Get.find<ApiClient>();

  bool _loading = true;
  List<Map<String, dynamic>> _weeks = [];
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiEndpoints.reportAttendanceTrend);
      setState(() {
        _weeks = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _avgRate {
    if (_weeks.isEmpty) return 0;
    final sum = _weeks.fold(0.0,
        (s, w) => s + ((w['attendanceRate'] as num?)?.toDouble() ?? 0));
    return sum / _weeks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('Attendance Trend'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _weeks.isEmpty
                  ? const ReportEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: ListView(
                        children: [
                          ReportSummaryStrip.items([
                            (label: 'Avg Rate',
                                value: '${_avgRate.toStringAsFixed(1)}%',
                                color: _avgRate >= 90
                                    ? const Color(0xFF4ADE80)
                                    : _avgRate >= 70
                                        ? AppColors.warning
                                        : const Color(0xFFFCA5A5)),
                            (label: 'Weeks', value: '${_weeks.length}',
                                color: null),
                          ]),
                          _AttendanceLineChart(weeks: _weeks),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: Column(
                              children: _weeks.reversed
                                  .map((w) => _WeekRow(w))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _AttendanceLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeks;
  const _AttendanceLineChart({required this.weeks});

  @override
  Widget build(BuildContext context) {
    final spots = weeks.asMap().entries.map((e) {
      final rate = (e.value['attendanceRate'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), rate);
    }).toList();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('Weekly Attendance Rate',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.bodyText)),
          ),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.orange,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.orange.withValues(alpha: 0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: spot.y >= 90
                            ? AppColors.success
                            : spot.y >= 70
                                ? AppColors.warning
                                : AppColors.error,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= weeks.length) {
                          return const SizedBox();
                        }
                        final label = weeks[idx]['weekLabel'] as String?
                            ?? 'W${idx + 1}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label.length > 4 ? label.substring(0, 4) : label,
                            style: TextStyle(
                                fontSize: 9, color: AppColors.mutedText),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border, strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.navy,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final label = idx < weeks.length
                          ? (weeks[idx]['weekLabel'] as String? ?? 'W${idx + 1}')
                          : '';
                      return LineTooltipItem(
                        '$label\n${s.y.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final Map<String, dynamic> w;
  const _WeekRow(this.w);

  @override
  Widget build(BuildContext context) {
    final label   = w['weekLabel']      as String? ?? '—';
    final rate    = (w['attendanceRate'] as num?)?.toDouble() ?? 0;
    final present = (w['presentCount']  as num?)?.toInt() ?? 0;
    final total   = (w['totalStaff']    as num?)?.toInt() ?? 0;

    final color = rate >= 90 ? AppColors.success
        : rate >= 70 ? AppColors.warning : AppColors.error;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (total > 0)
                  Text('$present / $total staff present',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          Text('${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700,
                  fontFamily: 'Inter', fontSize: 16)),
        ],
      ),
    );
  }
}
