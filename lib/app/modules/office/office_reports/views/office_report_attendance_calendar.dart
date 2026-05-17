import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_widgets.dart';

class OfficeReportAttendanceCalendar extends StatefulWidget {
  const OfficeReportAttendanceCalendar({super.key});

  @override
  State<OfficeReportAttendanceCalendar> createState() =>
      _OfficeReportAttendanceCalendarState();
}

class _OfficeReportAttendanceCalendarState
    extends State<OfficeReportAttendanceCalendar> {
  final _api = Get.find<ApiClient>();

  int _year  = DateTime.now().year;
  int _month = DateTime.now().month;

  bool _loading = true;
  List<Map<String, dynamic>> _staff = [];
  List<int> _workingDays = [];
  String? _error;
  String _search = '';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(
        ApiEndpoints.reportAttendanceCalendar,
        params: {'year': '$_year', 'month': '$_month'},
      );
      final d = (res.data as Map?)?['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _staff = (d['staff'] as List? ?? []).cast<Map<String, dynamic>>();
        _workingDays = (d['workingDays'] as List? ?? [])
            .cast<int>()..sort();
        if (_workingDays.isEmpty) {
          // Fallback: generate days in month
          final daysInMonth = DateTime(_year, _month + 1, 0).day;
          _workingDays = List.generate(daysInMonth, (i) => i + 1);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _prevMonth() {
    setState(() {
      _month--;
      if (_month < 1) { _month = 12; _year--; }
    });
    _fetch();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year >= now.year && _month >= now.month) return;
    setState(() {
      _month++;
      if (_month > 12) { _month = 1; _year++; }
    });
    _fetch();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _staff;
    final q = _search.toLowerCase();
    return _staff.where((s) =>
        (s['name'] as String? ?? '').toLowerCase().contains(q) ||
        (s['role'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: const Text('Attendance Calendar'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          _MonthPicker(
            year: _year, month: _month,
            onPrev: _prevMonth, onNext: _nextMonth,
          ),
          if (!_loading && _staff.isNotEmpty)
            ReportSummaryStrip.items([
              (label: 'Staff', value: '${_staff.length}', color: null),
              (label: 'Working Days', value: '${_workingDays.length}', color: null),
            ]),
          ReportSearchBar(
            hint: 'Search staff…',
            onChanged: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: _loading
                ? const ReportLoadingList()
                : _error != null
                    ? ReportErrorState(onRetry: _fetch)
                    : _filtered.isEmpty
                        ? const ReportEmptyState(
                            message: 'No attendance data for this month')
                        : _AttendanceGrid(
                            staff: _filtered,
                            workingDays: _workingDays,
                          ),
          ),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthPicker({
    required this.year, required this.month,
    required this.onPrev, required this.onNext,
  });

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentOrFuture = year >= now.year && month >= now.month;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 22),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              '${_months[month]} $year',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: isCurrentOrFuture ? null : onNext,
            icon: Icon(Icons.chevron_right, size: 22,
                color: isCurrentOrFuture ? AppColors.border : null),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AttendanceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> staff;
  final List<int> workingDays;
  const _AttendanceGrid({required this.staff, required this.workingDays});

  @override
  Widget build(BuildContext context) {
    // Show up to 15 days to avoid overflow on small screens
    final displayDays = workingDays.length > 15
        ? workingDays.sublist(workingDays.length - 15)
        : workingDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: day numbers
          _GridRow(
            leading: const SizedBox(width: 90),
            cells: displayDays.map((d) => _DayHeader('$d')).toList(),
          ),
          const Divider(height: 1),
          const SizedBox(height: 4),
          ...staff.map((s) {
            final name       = s['name'] as String? ?? '—';
            final role       = s['role'] as String? ?? '';
            final attendance = (s['attendance'] as Map?)
                ?.map((k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v));

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _GridRow(
                leading: SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.length > 12 ? '${name.substring(0, 12)}…' : name,
                        style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(_roleShort(role),
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText, fontSize: 9)),
                    ],
                  ),
                ),
                cells: displayDays.map((d) {
                  final status = attendance?[d] as String?;
                  return _AttendanceCell(status: status);
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 12),
          // Legend
          Wrap(spacing: 12, children: [
            _LegendItem(AppColors.success, 'Present'),
            _LegendItem(AppColors.error, 'Absent'),
            _LegendItem(AppColors.warning, 'Leave'),
            _LegendItem(AppColors.border, 'Holiday'),
          ]),
        ],
      ),
    );
  }

  static String _roleShort(String role) {
    final map = {
      'DRIVER': 'Driver', 'CLEANER': 'Cleaner',
      'SERVICE_MEN': 'Service', 'OFFICE_STAFF': 'Office',
      'SUPERVISOR': 'Supervisor',
    };
    return map[role] ?? role;
  }
}

class _GridRow extends StatelessWidget {
  final Widget leading;
  final List<Widget> cells;
  const _GridRow({required this.leading, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            children: cells
                .map((c) => Expanded(child: Center(child: c)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);
  @override
  Widget build(BuildContext context) {
    return Text(day,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedText, fontSize: 10,
            fontWeight: FontWeight.w600));
  }
}

class _AttendanceCell extends StatelessWidget {
  final String? status;
  const _AttendanceCell({this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final icon  = _icon(status);

    return Container(
      width: 16, height: 16,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 10, color: color),
    );
  }

  Color _color(String? s) {
    switch (s) {
      case 'PRESENT': return AppColors.success;
      case 'ABSENT':  return AppColors.error;
      case 'LEAVE':   return AppColors.warning;
      case 'HOLIDAY': return AppColors.border;
      default:        return AppColors.background;
    }
  }

  IconData _icon(String? s) {
    switch (s) {
      case 'PRESENT': return Icons.check;
      case 'ABSENT':  return Icons.close;
      case 'LEAVE':   return Icons.beach_access;
      case 'HOLIDAY': return Icons.star;
      default:        return Icons.remove;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedText, fontSize: 10)),
    ]);
  }
}
