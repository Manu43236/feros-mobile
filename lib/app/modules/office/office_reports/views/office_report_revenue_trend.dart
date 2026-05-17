import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/number_utils.dart';
import 'report_widgets.dart';

class OfficeReportRevenueTrend extends StatefulWidget {
  const OfficeReportRevenueTrend({super.key});

  @override
  State<OfficeReportRevenueTrend> createState() =>
      _OfficeReportRevenueTrendState();
}

class _OfficeReportRevenueTrendState
    extends State<OfficeReportRevenueTrend> {
  final _api = Get.find<ApiClient>();

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
      final res = await _api.get(ApiEndpoints.reportRevenueTrend);
      setState(() {
        _data = ((res.data as Map)['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _maxRevenue => _data.fold(0.0,
      (m, r) => max(m, (r['totalRevenue'] as num?)?.toDouble() ?? 0));

  double get _total12m => _data.fold(0.0,
      (s, r) => s + ((r['totalRevenue'] as num?)?.toDouble() ?? 0));

  String get _momChange {
    if (_data.length < 2) return '';
    final curr = (_data.first['totalRevenue'] as num?)?.toDouble() ?? 0;
    final prev = (_data[1]['totalRevenue'] as num?)?.toDouble() ?? 0;
    if (prev == 0) return '';
    final pct = (curr - prev) / prev * 100;
    return '${pct >= 0 ? '↑' : '↓'} ${pct.abs().toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final thisMonth = _data.isNotEmpty
        ? (_data.first['totalRevenue'] as num?)?.toDouble() ?? 0
        : 0.0;
    final mom = _momChange;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Revenue Trend'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: _loading
          ? const ReportLoadingList()
          : _error != null
              ? ReportErrorState(onRetry: _fetch)
              : _data.isEmpty
                  ? const ReportEmptyState(message: 'No revenue data available')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.navy,
                      child: ListView(
                        children: [
                          ReportSummaryStrip.items([
                            (
                              label: 'This Month',
                              value: FerosNumberUtils.formatCurrencyCompact(thisMonth),
                              color: const Color(0xFF4ADE80),
                            ),
                            if (mom.isNotEmpty)
                              (
                                label: 'vs Last Month',
                                value: mom,
                                color: mom.startsWith('↑')
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFFCA5A5),
                              ),
                            (
                              label: '12-Month Total',
                              value: FerosNumberUtils.formatCurrencyCompact(_total12m),
                              color: null,
                            ),
                          ]),
                          _RevenueBarChart(
                            chartData: _data.reversed.toList(),
                            maxRevenue: _maxRevenue,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: Column(
                              children: _data
                                  .map((r) => _RevenueTrendRow(r))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _RevenueBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> chartData; // oldest → newest
  final double maxRevenue;
  const _RevenueBarChart({required this.chartData, required this.maxRevenue});

  @override
  State<_RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<_RevenueBarChart> {
  int? _touchedIndex;

  static const _monthShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final data = widget.chartData;
    final maxY = max(widget.maxRevenue * 1.2, 1.0);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              '12-Month Revenue',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.bodyText),
            ),
          ),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: data.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  final isCurrent =
                      r['year'] == now.year && r['month'] == now.month;
                  final revenue =
                      (r['totalRevenue'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: isCurrent
                            ? AppColors.navy
                            : _touchedIndex == i
                                ? const Color(0xFF047857)
                                : const Color(0xFF059669),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ],
                  );
                }).toList(),
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
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        final month = (data[idx]['month'] as int? ?? 1)
                            .clamp(1, 12);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _monthShort[month],
                            style: TextStyle(
                              fontSize: 9,
                              color: _touchedIndex == idx
                                  ? AppColors.navy
                                  : AppColors.mutedText,
                              fontWeight: _touchedIndex == idx
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.spot == null) {
                        _touchedIndex = null;
                      } else {
                        _touchedIndex =
                            response!.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.navy,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    getTooltipItem: (group, _, rod, _) {
                      final r = data[group.x];
                      final count = r['invoiceCount'] as int? ?? 0;
                      return BarTooltipItem(
                        '${r['period']}\n',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        children: [
                          TextSpan(
                            text: FerosNumberUtils.formatCurrencyCompact(
                                rod.toY),
                            style: const TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: '  $count inv',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 0, 4),
            child: Row(
              children: [
                _LegendDot(AppColors.navy, 'Current month'),
                const SizedBox(width: 16),
                _LegendDot(const Color(0xFF059669), 'Previous months'),
              ],
            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedText, fontSize: 10)),
      ],
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _RevenueTrendRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _RevenueTrendRow(this.r);

  @override
  Widget build(BuildContext context) {
    final period   = r['period']       as String? ?? '—';
    final invCount = r['invoiceCount'] as int? ?? 0;
    final revenue  = (r['totalRevenue'] as num?)?.toDouble() ?? 0;
    final tax      = (r['taxAmount']   as num?)?.toDouble() ?? 0;
    final now      = DateTime.now();
    final isCurrent = r['year'] == now.year && r['month'] == now.month;

    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(period,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? AppColors.navy
                                : AppColors.bodyText)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Current',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$invCount invoice${invCount != 1 ? 's' : ''}'
                  '  ·  Tax ${FerosNumberUtils.formatCurrencyCompact(tax)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Text(
            FerosNumberUtils.formatCurrencyCompact(revenue),
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
