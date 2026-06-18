import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/shimmer_card.dart';
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
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: Text(
          'My Attendance',
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ShimmerCard(height: 80),
              ShimmerCard(height: 56),
              ShimmerCard(height: 72),
              ShimmerCard(height: 72),
              ShimmerCard(height: 72),
            ],
          );
        }
        if (controller.state.value == ViewState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load attendance',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        // Read all reactive values here — children are plain widgets
        final records     = controller.records.toList();
        final todayRecord = controller.todayRecord;
        final markLoading = controller.markLoading.value;
        final stats = (
          present: controller.present,
          absent:  controller.absent,
          half:    controller.half,
          leave:   controller.leave,
          pending: controller.pending,
        );

        return RefreshIndicator(
          color: AppColors.navy,
          onRefresh: controller.fetchAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _TodayCard(
                todayRecord: todayRecord,
                markLoading: markLoading,
                onMark: () => _showMarkSheet(context, controller),
              ),
              const SizedBox(height: 16),
              _StatsRow(
                present: stats.present,
                absent:  stats.absent,
                half:    stats.half,
                leave:   stats.leave,
                pending: stats.pending,
              ),
              const SizedBox(height: 16),
              _RecordsList(records: records),
            ],
          ),
        );
      }),
    );
  }
}

// ── Today Card ────────────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final Map<String, dynamic>? todayRecord;
  final bool markLoading;
  final VoidCallback onMark;
  const _TodayCard({required this.todayRecord, required this.markLoading, required this.onMark});

  @override
  Widget build(BuildContext context) {
    final marked = todayRecord != null;
    final color  = marked ? AppColors.success : AppColors.warning;
    final bg     = color.withValues(alpha: 0.08);
    final border = color.withValues(alpha: 0.3);
    final now    = DateTime.now();
    final dayStr = '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} ${_month(now.month)} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.calendar_today_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today — $dayStr',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (marked) ...[
                  Wrap(spacing: 6, children: [
                    _TypeBadge(type: todayRecord!['attendanceTypeName'] as String? ?? ''),
                    _ApprovalBadge(status: todayRecord!['approvalStatus'] as String? ?? ''),
                  ]),
                ] else
                  Text('Not marked yet',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ],
            ),
          ),
          if (!marked) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: markLoading ? null : onMark,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: markLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Mark', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int present, absent, half, leave, pending;
  const _StatsRow({
    required this.present,
    required this.absent,
    required this.half,
    required this.leave,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Present', present, AppColors.success),
      ('Absent',  absent,  AppColors.error),
      ('Half',    half,    AppColors.warning),
      ('Leave',   leave,   AppColors.navy),
      ('Pending', pending, AppColors.mutedText),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final e = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 5 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: e.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('${e.$2}',
                    style: AppTextStyles.heading4.copyWith(color: e.$3, fontSize: 18)),
                const SizedBox(height: 2),
                Text(e.$1,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText, fontSize: 9),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Records List ──────────────────────────────────────────────────────────────
class _RecordsList extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  const _RecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    final now        = DateTime.now();
    final monthLabel = '${_month(now.month)} ${now.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("This Month's Records — $monthLabel",
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.mutedText),
                const SizedBox(height: 10),
                Text('No attendance records this month',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ],
            ),
          )
        else
          ...records.map((r) => _AttendanceCard(record: r)),
      ],
    );
  }
}

// ── Mark Sheet ────────────────────────────────────────────────────────────────
void _showMarkSheet(BuildContext context, SupervisorMyAttendanceController ctrl) {
  final remarks    = TextEditingController();
  final selfieFile = Rxn<File>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Obx(() => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Mark Today\'s Attendance',
                style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(_formatToday(),
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),

            _SelfieBox(selfieFile: selfieFile, disabled: ctrl.markLoading.value),
            const SizedBox(height: 12),

            Text('Remarks (Optional)',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 4),
            TextField(
              controller: remarks,
              decoration: InputDecoration(
                hintText: 'Optional',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Text('Attendance will be reviewed and approved by admin.',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.markLoading.value
                    ? null
                    : () async {
                        final ok = await ctrl.markPresent(
                          selfieFile: selfieFile.value,
                          remarks: remarks.text,
                        );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                          Get.snackbar('Success', 'Attendance marked',
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM);
                        } else if (!ok && context.mounted) {
                          Get.snackbar('Error', 'Failed to mark attendance',
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                icon: ctrl.markLoading.value
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  ctrl.markLoading.value ? 'Marking…' : 'Mark Present',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      )),
    ),
  );
}

// ── Selfie Box ────────────────────────────────────────────────────────────────
class _SelfieBox extends StatelessWidget {
  final Rxn<File> selfieFile;
  final bool disabled;
  const _SelfieBox({required this.selfieFile, required this.disabled});

  Future<void> _pick() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile != null) selfieFile.value = File(xFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : _pick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: selfieFile.value == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_front_outlined,
                      size: 32, color: AppColors.mutedText),
                  const SizedBox(height: 8),
                  Text('Tap to take selfie (Optional)',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(selfieFile.value!, fit: BoxFit.cover),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: disabled ? null : () => selfieFile.value = null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6, right: 6,
                    child: GestureDetector(
                      onTap: disabled ? null : _pick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Retake',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _formatToday() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
}

String _weekday(int w) => const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];
String _month(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

// ── Attendance Card ───────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date           = record['attendanceDate']    as String? ?? '';
    final typeName       = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']    as String? ?? '';
    final leaveTypeName  = record['leaveTypeName']     as String?;
    final approvedByName = record['approvedByName']    as String?;
    final remarks        = record['remarks']           as String?;
    final markedAt       = record['markedAt']          as String?;
    final locationName   = record['locationName']      as String?;

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
                if (leaveTypeName != null && leaveTypeName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Leave: $leaveTypeName',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
                if (approvedByName != null && approvedByName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Approved by $approvedByName',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
                if (markedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Marked at ${FerosDateUtils.formatDateTime(markedAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
                if (locationName != null && locationName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.mutedText),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationName,
                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
      return (AppColors.navy, Icons.beach_access_outlined);
    }
    if (n.contains('WEEKLY') || n.contains('OFF')) {
      return (AppColors.mutedText, Icons.weekend_outlined);
    }
    return (AppColors.mutedText, Icons.event_note_outlined);
  }

  (Color, String) _approvalStyle(String status) {
    switch (status) {
      case 'PENDING':  return (AppColors.warning, 'Pending');
      case 'APPROVED': return (AppColors.success, 'Approved');
      case 'REJECTED': return (AppColors.error,   'Rejected');
      default:         return (AppColors.mutedText, status);
    }
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final n = type.toUpperCase();
    final Color color;
    if (n.contains('PRESENT') && !n.contains('HALF')) color = AppColors.success;
    else if (n.contains('ABSENT')) color = AppColors.error;
    else if (n.contains('HALF'))   color = AppColors.warning;
    else if (n.contains('LEAVE'))  color = AppColors.navy;
    else color = AppColors.mutedText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(type,
          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Approval Badge ────────────────────────────────────────────────────────────
class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'PENDING'  => (AppColors.warning, 'Pending'),
      'APPROVED' => (AppColors.success, 'Approved'),
      'REJECTED' => (AppColors.error,   'Rejected'),
      _          => (AppColors.mutedText, status),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
