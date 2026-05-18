import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/supervisor_my_attendance_controller.dart';

class SupervisorMyAttendanceView
    extends GetView<SupervisorMyAttendanceController> {
  const SupervisorMyAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          'lbl_my_attendance'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.navy));
        }
        if (controller.state.value == ViewState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('lbl_failed_load_att'.tr,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchRecords,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('btn_retry'.tr),
                ),
              ],
            ),
          );
        }
        if (controller.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 52, color: AppColors.mutedText),
                const SizedBox(height: 12),
                Text('lbl_no_att_records'.tr,
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 6),
                Text('lbl_att_history_appear'.tr,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.navy,
          onRefresh: controller.fetchRecords,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: controller.records.length,
            itemBuilder: (_, i) =>
                _AttendanceCard(record: controller.records[i]),
          ),
        );
      }),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date         = record['date']               as String? ?? '';
    final typeName     = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']   as String? ?? '';
    final remarks      = record['remarks']            as String?;
    final markedAt     = record['createdAt']          as String?;

    final (typeColor, typeIcon) = _typeStyle(typeName);
    final (approvalColor, approvalLabel) = _approvalStyle(approvalStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _dayNum(date),
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.navy, fontSize: 20),
                ),
                Text(
                  _monthShort(date),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(typeName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.bodyText)),
                    const Spacer(),
                    if (approvalStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: approvalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          approvalLabel,
                          style: AppTextStyles.caption.copyWith(
                              color: approvalColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                if (markedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${'lbl_marked_at_time'.tr} ${FerosDateUtils.formatDateTime(markedAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    remarks,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayNum(String iso) {
    try {
      return DateTime.parse(iso).day.toString().padLeft(2, '0');
    } catch (_) {
      return '—';
    }
  }

  String _monthShort(String iso) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    try {
      final d = DateTime.parse(iso);
      return months[d.month - 1];
    } catch (_) {
      return '';
    }
  }

  (Color, IconData) _typeStyle(String name) {
    final n = name.toUpperCase();
    if (n.contains('PRESENT') && !n.contains('HALF')) {
      return (AppColors.success, Icons.check_circle_outline);
    }
    if (n.contains('ABSENT')) {
      return (AppColors.error, Icons.cancel_outlined);
    }
    if (n.contains('HALF')) {
      return (AppColors.warning, Icons.timelapse_outlined);
    }
    if (n.contains('LEAVE')) {
      return (AppColors.info, Icons.beach_access_outlined);
    }
    if (n.contains('WEEKLY') || n.contains('OFF')) {
      return (AppColors.mutedText, Icons.weekend_outlined);
    }
    return (AppColors.mutedText, Icons.event_note_outlined);
  }

  (Color, String) _approvalStyle(String status) {
    switch (status) {
      case 'PENDING':
        return (AppColors.warning, 'status_pending'.tr);
      case 'APPROVED':
        return (AppColors.success, 'status_approved'.tr);
      case 'REJECTED':
        return (AppColors.error, 'status_rejected'.tr);
      default:
        return (AppColors.mutedText, status);
    }
  }
}
