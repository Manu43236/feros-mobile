import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'attendance_sheet.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final api = Get.find<ApiClient>();
      final from = DateTime(_month.year, _month.month, 1);
      final to = DateTime(_month.year, _month.month + 1, 0);
      final res = await api.get(
        ApiEndpoints.myAttendance,
        params: {
          'from': _fmt(from),
          'to': _fmt(to),
        },
      );
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      setState(() => _records = raw.cast<Map<String, dynamic>>());
    } catch (_) {
      FerosSnackbar.error('Failed to load attendance');
    }
    setState(() => _isLoading = false);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
      _selectedDay = null;
    });
    _fetch();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() {
      _month = DateTime(_month.year, _month.month + 1);
      _selectedDay = null;
    });
    _fetch();
  }

  Map<int, Map<String, dynamic>> get _recordsByDay {
    final map = <int, Map<String, dynamic>>{};
    for (final r in _records) {
      final dateStr = r['attendanceDate'] as String?;
      if (dateStr == null) continue;
      final d = DateTime.tryParse(dateStr);
      if (d != null) map[d.day] = r;
    }
    return map;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  bool get _todayMarked {
    final today = DateTime.now().day;
    return _isCurrentMonth && _recordsByDay.containsKey(today);
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _recordsByDay;

    // Summary counts
    int present = 0, absent = 0, halfDay = 0, onLeave = 0;
    for (final r in _records) {
      final type =
          (r['attendanceTypeName'] as String? ?? '').toLowerCase();
      if (type.contains('present')) present++;
      else if (type.contains('absent')) absent++;
      else if (type.contains('half')) halfDay++;
      else if (type.contains('leave')) onLeave++;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Attendance',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        actions: [
          if (_isCurrentMonth && !_todayMarked)
            TextButton(
              onPressed: () => showMarkAttendanceSheet(
                context,
                onMarked: () {
                  _fetch();
                },
              ),
              child: const Text('Mark Today',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.navy,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Calendar Card ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Month navigator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: AppColors.navy),
                              onPressed: _prevMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              _monthLabel(_month),
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.navy),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right,
                                  color: _isCurrentMonth
                                      ? AppColors.border
                                      : AppColors.navy),
                              onPressed: _nextMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Weekday headers
                        Row(
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((d) => Expanded(
                                    child: Center(
                                      child: Text(d,
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  color: AppColors.mutedText,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),

                        // Calendar grid
                        _CalendarGrid(
                          month: _month,
                          recordsByDay: byDay,
                          selectedDay: _selectedDay,
                          onDayTap: (day) =>
                              setState(() => _selectedDay =
                                  _selectedDay == day ? null : day),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Summary Row ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryChip(
                            label: 'Present',
                            count: present,
                            color: const Color(0xFF16A34A)),
                        _SummaryChip(
                            label: 'Absent',
                            count: absent,
                            color: const Color(0xFFDC2626)),
                        _SummaryChip(
                            label: 'Half Day',
                            count: halfDay,
                            color: const Color(0xFFD97706)),
                        _SummaryChip(
                            label: 'Leave',
                            count: onLeave,
                            color: AppColors.navy),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Selected Day Detail ──────────────────────
                  if (_selectedDay != null) ...[
                    _DayDetail(
                      day: _selectedDay!,
                      month: _month,
                      record: byDay[_selectedDay],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Legend ──────────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _Legend(color: const Color(0xFF16A34A), label: 'Present'),
                      _Legend(
                          color: const Color(0xFFDC2626), label: 'Absent'),
                      _Legend(
                          color: const Color(0xFFD97706), label: 'Half Day'),
                      _Legend(color: AppColors.navy, label: 'Leave'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month]} ${d.year}';
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, Map<String, dynamic>> recordsByDay;
  final int? selectedDay;
  final void Function(int) onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.recordsByDay,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // Mon=0
    final today = DateTime.now();

    final cells = <Widget>[];

    // Empty cells before day 1
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= totalDays; day++) {
      final record = recordsByDay[day];
      final isToday = today.year == month.year &&
          today.month == month.month &&
          today.day == day;
      final isSelected = selectedDay == day;
      final isFuture = DateTime(month.year, month.month, day)
          .isAfter(today);

      cells.add(GestureDetector(
        onTap: isFuture ? null : () => onDayTap(day),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.navy
                    : isToday
                        ? AppColors.navy.withValues(alpha: 0.1)
                        : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.navy, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isFuture
                            ? AppColors.border
                            : AppColors.navy,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFuture || record == null
                    ? Colors.transparent
                    : _dotColor(
                        record['attendanceTypeName'] as String? ?? ''),
              ),
            ),
          ],
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: cells,
    );
  }

  Color _dotColor(String typeName) {
    final t = typeName.toLowerCase();
    if (t.contains('present')) return const Color(0xFF16A34A);
    if (t.contains('absent')) return const Color(0xFFDC2626);
    if (t.contains('half')) return const Color(0xFFD97706);
    if (t.contains('leave')) return AppColors.navy;
    return AppColors.mutedText;
  }
}

// ── Day Detail ────────────────────────────────────────────────────────────────
class _DayDetail extends StatelessWidget {
  final int day;
  final DateTime month;
  final Map<String, dynamic>? record;

  const _DayDetail(
      {required this.day, required this.month, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateLabel = '$day ${_monthName(month.month)} ${month.year}';

    if (record == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_busy_outlined,
                size: 18, color: AppColors.mutedText),
            const SizedBox(width: 10),
            Text('$dateLabel — No record',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ),
      );
    }

    final type = record!['attendanceTypeName'] as String? ?? '—';
    final status = record!['approvalStatus'] as String? ?? '—';
    final markedAt = record!['markedAt'] as String?;
    final dotColor = _dotColor(type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dotColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 8),
              Text(dateLabel,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.navy)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (status == 'APPROVED'
                          ? const Color(0xFF16A34A)
                          : status == 'REJECTED'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'APPROVED'
                      ? 'Approved'
                      : status == 'REJECTED'
                          ? 'Rejected'
                          : 'Pending',
                  style: AppTextStyles.caption.copyWith(
                    color: status == 'APPROVED'
                        ? const Color(0xFF16A34A)
                        : status == 'REJECTED'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(type,
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          if (markedAt != null) ...[
            const SizedBox(height: 4),
            Text('Marked at ${_formatTime(markedAt)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ],
          if (record!['selfieUrl'] != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showSelfie(context, record!['selfieUrl'] as String),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: record!['selfieUrl'] as String,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    height: 120,
                    color: AppColors.background,
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.mutedText),
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    height: 60,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.mutedText, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.camera_front_outlined,
                    size: 12, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text('Tap selfie to enlarge',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showSelfie(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (ctx, url) => const SizedBox(
                width: 60, height: 60,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (ctx, url, err) =>
                  const Icon(Icons.broken_image_outlined,
                      color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Color _dotColor(String typeName) {
    final t = typeName.toLowerCase();
    if (t.contains('present')) return const Color(0xFF16A34A);
    if (t.contains('absent')) return const Color(0xFFDC2626);
    if (t.contains('half')) return const Color(0xFFD97706);
    return AppColors.navy;
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return iso;
    }
  }
}

// ── Summary Chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: AppTextStyles.heading3.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}
