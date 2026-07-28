import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/driver_attendance_controller.dart';
import 'driver_attendance_sheet.dart';

class DriverAttendanceView extends GetView<DriverAttendanceController> {
  const DriverAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final byDay = controller.recordsByDay;
      final records = controller.records;

      int present = 0, absent = 0, halfDay = 0, onLeave = 0;
      for (final r in records) {
        final type = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
        if (type.contains('present'))
          present++;
        else if (type.contains('absent'))
          absent++;
        else if (type.contains('half'))
          halfDay++;
        else if (type.contains('leave'))
          onLeave++;
      }

      return controller.isLoading.value
          ? const ShimmerList(count: 6)
          : RefreshIndicator(
              onRefresh: controller.fetch,
              color: AppColors.navy,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Mark Today Banner ──────────────────────
                  if (controller.isCurrentMonth && !controller.todayMarked) ...[
                    GestureDetector(
                      onTap: () => showMarkAttendanceSheet(
                        context,
                        onMarked: controller.fetch,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'lbl_mark_today_attendance'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Calendar Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Month navigator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.navy,
                              ),
                              onPressed: controller.prevMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              _monthLabel(controller.month.value),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.navy,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: controller.isCurrentMonth
                                    ? AppColors.border
                                    : AppColors.navy,
                              ),
                              onPressed: controller.nextMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Weekday headers
                        Row(
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),

                        // Calendar grid
                        _CalendarGrid(
                          month: controller.month.value,
                          recordsByDay: byDay,
                          selectedDay: controller.selectedDay.value,
                          onDayTap: controller.selectDay,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Summary Row ────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryChip(
                          label: 'status_present'.tr,
                          count: present,
                          color: const Color(0xFF16A34A),
                        ),
                        _SummaryChip(
                          label: 'status_absent'.tr,
                          count: absent,
                          color: const Color(0xFFDC2626),
                        ),
                        _SummaryChip(
                          label: 'status_half_day'.tr,
                          count: halfDay,
                          color: const Color(0xFFD97706),
                        ),
                        _SummaryChip(
                          label: 'status_leave'.tr,
                          count: onLeave,
                          color: AppColors.navy,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Selected Day Detail ────────────────────
                  if (controller.selectedDay.value != null) ...[
                    _DayDetail(
                      day: controller.selectedDay.value!,
                      month: controller.month.value,
                      record: byDay[controller.selectedDay.value],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Legend ────────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _Legend(color: const Color(0xFF16A34A), label: 'status_present'.tr),
                      _Legend(color: const Color(0xFFDC2626), label: 'status_absent'.tr),
                      _Legend(color: const Color(0xFFD97706), label: 'status_half_day'.tr),
                      _Legend(color: AppColors.navy, label: 'status_leave'.tr),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Records List ──────────────────────────
                  if (records.isNotEmpty) ...[
                    Text(
                      'lbl_this_month_records'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...records.map((r) => _AttendanceListItem(record: r)),
                  ],
                ],
              ),
            );
    });
  }

  String _monthLabel(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];
    for (int i = 0; i < startOffset; i++) cells.add(const SizedBox());

    for (int day = 1; day <= totalDays; day++) {
      final record = recordsByDay[day];
      final isToday =
          today.year == month.year &&
          today.month == month.month &&
          today.day == day;
      final isSelected = selectedDay == day;
      final isFuture = DateTime(month.year, month.month, day).isAfter(today);

      cells.add(
        GestureDetector(
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
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
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
                          record['attendanceTypeName'] as String? ?? '',
                        ),
                ),
              ),
            ],
          ),
        ),
      );
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
  const _DayDetail({
    required this.day,
    required this.month,
    required this.record,
  });

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
            const Icon(
              Icons.event_busy_outlined,
              size: 18,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 10),
            Text(
              '$dateLabel — ${'lbl_no_record'.tr}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
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
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
              ),
              const Spacer(),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
          ),
          if (markedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${'lbl_marked_at'.tr} ${_formatTime(markedAt)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ],
          if (record!['locationName'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record!['locationName'] as String,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    height: 60,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.mutedText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.camera_front_outlined,
                  size: 12,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  'lbl_tap_selfie'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'APPROVED':
        color = const Color(0xFF16A34A);
        label = 'status_approved'.tr;
        break;
      case 'REJECTED':
        color = const Color(0xFFDC2626);
        label = 'status_rejected'.tr;
        break;
      default:
        color = const Color(0xFFD97706);
        label = 'status_pending'.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
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
                width: 60,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (ctx, url, err) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
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
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
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
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: AppTextStyles.heading3.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

// ── Attendance List Item ───────────────────────────────────────────────────────
class _AttendanceListItem extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceListItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr     = record['attendanceDate']    as String? ?? '';
    final type        = record['attendanceTypeName'] as String? ?? '—';
    final status      = record['approvalStatus']    as String? ?? 'PENDING';
    final markedAt    = record['markedAt']           as String?;
    final locationName = record['locationName']      as String?;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'status_approved'.tr;
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'status_rejected'.tr;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'status_pending'.tr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(dateStr),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type +
                      (markedAt != null ? '  ·  ${_formatTime(markedAt)}' : ''),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                if (locationName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: AppColors.mutedText),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) {
      return iso;
    }
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
