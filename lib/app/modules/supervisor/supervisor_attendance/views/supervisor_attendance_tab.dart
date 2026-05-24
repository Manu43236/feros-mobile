import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_attendance_controller.dart';
import '../../supervisor_my_attendance/controllers/supervisor_my_attendance_controller.dart';
import '../../supervisor_my_attendance/bindings/supervisor_my_attendance_binding.dart';

class SupervisorAttendanceTab extends StatefulWidget {
  const SupervisorAttendanceTab({super.key});

  @override
  State<SupervisorAttendanceTab> createState() =>
      _SupervisorAttendanceTabState();
}

class _SupervisorAttendanceTabState extends State<SupervisorAttendanceTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    SupervisorMyAttendanceBinding().dependencies();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────
        Container(
          color: AppColors.navy,
          child: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'My Attendance'),
            ],
          ),
        ),

        // ── Tab content ──────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _DailyTab(),
              _MyAttendanceSelfTab(tab: _tab),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Daily Tab (read-only attendance view) ─────────────────────────────────────
class _DailyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 56),
            ShimmerCard(height: 56),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
          ],
        );
      }
      if (ctrl.state.value == ViewState.error) {
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
                onPressed: ctrl.fetchAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: ctrl.fetchAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Date navigator ──────────────────────────
            _DailyDateBar(ctrl: ctrl),
            const SizedBox(height: 12),

            // ── Stats row ───────────────────────────────
            _DailyStatsRow(ctrl: ctrl),
            const SizedBox(height: 16),

            // ── Records list ────────────────────────────
            Text(
              'Attendance for ${ctrl.dateLabel}',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (ctrl.records.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No attendance marked for this date',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                  ),
                ),
              )
            else
              ...ctrl.records.map((r) => _DailyRecordCard(record: r)),
          ],
        ),
      );
    });
  }
}

// ── Date Navigator Bar ────────────────────────────────────────────────────────
class _DailyDateBar extends StatelessWidget {
  final SupervisorAttendanceController ctrl;
  const _DailyDateBar({required this.ctrl});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: Colors.white,
            onSurface: AppColors.bodyText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.changeDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => ctrl.shiftDay(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.navy),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 15, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Text(
                    ctrl.dateLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: ctrl.selectedDate.value.day == DateTime.now().day &&
                    ctrl.selectedDate.value.month == DateTime.now().month
                ? null
                : () => ctrl.shiftDay(1),
            icon: Icon(
              Icons.chevron_right,
              color: ctrl.selectedDate.value.day == DateTime.now().day &&
                      ctrl.selectedDate.value.month == DateTime.now().month
                  ? AppColors.border
                  : AppColors.navy,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    ));
  }
}

// ── Daily Stats Row ───────────────────────────────────────────────────────────
class _DailyStatsRow extends StatelessWidget {
  final SupervisorAttendanceController ctrl;
  const _DailyStatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Present', ctrl.present, AppColors.success),
      ('Absent',  ctrl.absent,  AppColors.error),
      ('Half',    ctrl.half,    AppColors.warning),
      ('Leave',   ctrl.leave,   AppColors.navy),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final e = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: e.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('${e.$2}',
                    style: AppTextStyles.heading4
                        .copyWith(color: e.$3, fontSize: 18)),
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

// ── Daily Record Card (read-only) ─────────────────────────────────────────────
class _DailyRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _DailyRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final userName     = record['userName']          as String? ?? '—';
    final roleName     = record['roleName']          as String?;
    final typeName     = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']  as String? ?? '';
    final leaveTypeName  = record['leaveTypeName']   as String?;
    final markedByName   = record['markedByName']    as String?;

    final (typeColor, typeIcon) = _typeStyle(typeName);
    final (approvalColor, approvalLabel) = _approvalStyle(approvalStatus);

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          if (roleName != null && roleName.isNotEmpty)
                            Text(roleName,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    if (approvalStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: approvalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(approvalLabel,
                            style: AppTextStyles.caption.copyWith(
                                color: approvalColor,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(typeIcon, size: 13, color: typeColor),
                    const SizedBox(width: 4),
                    Text(typeName,
                        style: AppTextStyles.caption
                            .copyWith(color: typeColor, fontWeight: FontWeight.w600)),
                    if (leaveTypeName != null && leaveTypeName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('· $leaveTypeName',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ],
                  ],
                ),
                if (markedByName != null && markedByName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Marked by $markedByName',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _typeStyle(String name) {
    final n = name.toUpperCase();
    if (n.contains('PRESENT') && !n.contains('HALF')) {
      return (AppColors.success, Icons.check_circle_outline);
    }
    if (n.contains('ABSENT'))   return (AppColors.error,     Icons.cancel_outlined);
    if (n.contains('HALF'))     return (AppColors.warning,   Icons.timelapse_outlined);
    if (n.contains('LEAVE'))    return (AppColors.navy,      Icons.beach_access_outlined);
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

// ── My Attendance Self Tab ────────────────────────────────────────────────────
class _MyAttendanceSelfTab extends StatefulWidget {
  final TabController tab;
  const _MyAttendanceSelfTab({required this.tab});

  @override
  State<_MyAttendanceSelfTab> createState() => _MyAttendanceSelfTabState();
}

class _MyAttendanceSelfTabState extends State<_MyAttendanceSelfTab> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.tab.index;
    widget.tab.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (mounted) setState(() => _currentTab = widget.tab.index);
  }

  @override
  void dispose() {
    widget.tab.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SupervisorMyAttendanceController>();
    return Obx(() {
      if (ctrl.state.value == ViewState.loading) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            ShimmerCard(height: 80),
            ShimmerCard(height: 56),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
            ShimmerCard(height: 72),
          ],
        );
      }
      if (ctrl.state.value == ViewState.error) {
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
                onPressed: ctrl.fetchAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      final records = ctrl.records.toList();
      final todayRecord = ctrl.todayRecord;
      final marked = todayRecord != null;
      final now = DateTime.now();
      final dayStr =
          '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} ${_month(now.month)} ${now.year}';

      return Stack(
        children: [
          RefreshIndicator(
            color: AppColors.navy,
            onRefresh: ctrl.fetchAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                // ── Today card ─────────────────────────────
                _buildTodayCard(context, ctrl, marked, todayRecord, dayStr),
                const SizedBox(height: 14),

                // ── Stats row ──────────────────────────────
                _buildStatsRow(ctrl),
                const SizedBox(height: 14),

                // ── Monthly records ────────────────────────
                Text(
                  "This Month's Records — ${_month(now.month)} ${now.year}",
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No attendance records this month',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ),
                  )
                else
                  ...records.map((r) => _AttendanceRecordCard(record: r)),
              ],
            ),
          ),

          // ── FAB (mark own attendance) ─────────────────
          if (_currentTab == 1 && !marked)
            Positioned(
              bottom: 16,
              right: 16,
              child: Obx(() => FloatingActionButton.extended(
                onPressed: ctrl.markLoading.value
                    ? null
                    : () => _showMarkBottomSheet(context, ctrl),
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                icon: ctrl.markLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.how_to_reg_outlined),
                label: const Text(
                  'Mark Attendance',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
              )),
            ),
        ],
      );
    });
  }

  Widget _buildTodayCard(
    BuildContext context,
    SupervisorMyAttendanceController ctrl,
    bool marked,
    Map<String, dynamic>? todayRecord,
    String dayStr,
  ) {
    final color = marked ? AppColors.success : AppColors.warning;
    final bg = color.withValues(alpha: 0.08);
    final border = color.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                Icon(Icons.calendar_today_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today — $dayStr',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (marked)
                  Wrap(spacing: 6, children: [
                    _TypeBadge(
                        type: todayRecord!['attendanceTypeName'] as String? ??
                            ''),
                    _ApprovalBadge(
                        status:
                            todayRecord['approvalStatus'] as String? ?? ''),
                  ])
                else
                  Text('Not marked yet',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SupervisorMyAttendanceController ctrl) {
    final items = [
      ('Present', ctrl.present, AppColors.success),
      ('Absent', ctrl.absent, AppColors.error),
      ('Half', ctrl.half, AppColors.warning),
      ('Leave', ctrl.leave, AppColors.navy),
      ('Pending', ctrl.pending, AppColors.mutedText),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final e = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 5 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: e.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: e.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('${e.$2}',
                    style: AppTextStyles.heading4
                        .copyWith(color: e.$3, fontSize: 16)),
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

// ── Mark Bottom Sheet ─────────────────────────────────────────────────────────
void _showMarkBottomSheet(
    BuildContext context, SupervisorMyAttendanceController ctrl) {
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
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Mark Today\'s Attendance',
                style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(
              _todayLabel(),
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),

            // Selfie
            _SelfieBox(selfieFile: selfieFile, disabled: ctrl.markLoading.value),
            const SizedBox(height: 12),

            // Remarks
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

String _todayLabel() {
  final d = DateTime.now();
  return '${_weekday(d.weekday)}, ${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
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

// ── Attendance Record Card ────────────────────────────────────────────────────
class _AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date           = record['attendanceDate']    as String? ?? '';
    final typeName       = record['attendanceTypeName'] as String? ?? '—';
    final approvalStatus = record['approvalStatus']    as String? ?? '';
    final leaveTypeName  = record['leaveTypeName']     as String?;
    final approvedByName = record['approvedByName']    as String?;
    final remarks        = record['remarks']           as String?;
    final markedAt       = record['markedAt']          as String?;

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
                Text(_dayNum(date),
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy, fontSize: 20)),
                Text(_monthShort(date),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
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
                        child: Text(approvalLabel,
                            style: AppTextStyles.caption.copyWith(
                                color: approvalColor,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (leaveTypeName != null && leaveTypeName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Leave: $leaveTypeName',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (approvedByName != null && approvedByName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Approved by $approvedByName',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (markedAt != null) ...[
                  const SizedBox(height: 3),
                  Text('Marked at ${FerosDateUtils.formatDateTime(markedAt)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(remarks,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
      return months[DateTime.parse(iso).month - 1];
    } catch (_) {
      return '';
    }
  }

  (Color, IconData) _typeStyle(String name) {
    final n = name.toUpperCase();
    if (n.contains('PRESENT') && !n.contains('HALF')) {
      return (AppColors.success, Icons.check_circle_outline);
    }
    if (n.contains('ABSENT'))   return (AppColors.error,     Icons.cancel_outlined);
    if (n.contains('HALF'))     return (AppColors.warning,   Icons.timelapse_outlined);
    if (n.contains('LEAVE'))    return (AppColors.navy,      Icons.beach_access_outlined);
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
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
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
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _weekday(int w) =>
    const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];
String _month(int m) => const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m];

