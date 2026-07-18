import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../controllers/supervisor_dashboard_controller.dart' show SupervisorDashboardController, VehicleAlert;
import '../../supervisor_shell/controllers/supervisor_shell_controller.dart';
import '../../supervisor_vehicles/views/supervisor_vehicles_view.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicles_binding.dart';
import '../../supervisor_crew/views/supervisor_crew_view.dart';
import '../../supervisor_crew/bindings/supervisor_crew_binding.dart';
import '../../supervisor_lrs/views/supervisor_lrs_view.dart';
import '../../supervisor_lrs/bindings/supervisor_lrs_binding.dart';
import '../../supervisor_orders/controllers/supervisor_orders_controller.dart';
import '../../supervisor_my_attendance/bindings/supervisor_my_attendance_binding.dart';
import '../../supervisor_my_attendance/views/supervisor_my_attendance_view.dart';

class SupervisorDashboard extends StatelessWidget {
  final SupervisorDashboardController controller;
  const SupervisorDashboard({super.key, required this.controller});

  void _goToTab(int index) =>
      Get.find<SupervisorShellController>().onTabTapped(index);

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
      children: [

        // ── My Attendance Quick-Action ─────────────────────────────
        _MyAttendanceCard(controller: controller),
        const SizedBox(height: 14),

        // ── Orders ─────────────────────────────────────────────────
        _SectionCard(
          icon: Icons.assignment_outlined,
          title: 'nav_orders'.tr,
          accentColor: AppColors.navy,
          onTap: () => _goToTab(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TotalBadge(value: controller.orderTotal.value, color: AppColors.navy),
              const SizedBox(height: 12),
              _StatRow(stats: [
                _StatItem('status_active'.tr,    controller.orderActive.value,    AppColors.orderActive,
                    onTap: () { _goToTab(1); Get.find<SupervisorOrdersController>().toggleFilter('IN_TRANSIT'); }),
                _StatItem('status_pending'.tr,   controller.orderPending.value,   AppColors.orderPending,
                    onTap: () { _goToTab(1); Get.find<SupervisorOrdersController>().toggleFilter('PENDING'); }),
                _StatItem('status_completed'.tr, controller.orderCompleted.value, AppColors.orderCompleted),
                _StatItem('status_delivered'.tr, controller.orderDelivered.value, AppColors.lrDelivered,
                    onTap: () { _goToTab(1); Get.find<SupervisorOrdersController>().toggleFilter('DELIVERED'); }),
                _StatItem('status_cancelled'.tr, controller.orderCancelled.value, AppColors.orderCancelled,
                    onTap: () { _goToTab(1); Get.find<SupervisorOrdersController>().toggleFilter('CANCELLED'); }),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Assignments ────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.people_alt_outlined,
          title: 'lbl_assignments'.tr,
          accentColor: AppColors.orange,
        ),
        const SizedBox(height: 8),

        // Vehicles sub-card
        _SubCard(
          icon: Icons.garage_outlined,
          label: 'lbl_vehicles'.tr,
          total: controller.vehicleTotal.value,
          color: AppColors.navy,
          onTap: () => Get.to(
            () => const SupervisorVehiclesView(),
            binding: SupervisorVehiclesBinding(),
            transition: Transition.cupertino,
          ),
          stats: [
            _StatItem('lbl_available'.tr,    controller.vehicleAvailable.value, AppColors.success),
            _StatItem('lbl_on_trip_chip'.tr, controller.vehicleOnTrip.value,    AppColors.lrInTransit),
            _StatItem('lbl_breakdown_chip'.tr,controller.vehicleBreakdown.value, AppColors.error),
            _StatItem('lbl_inactive'.tr,     controller.vehicleInactive.value,  AppColors.mutedText),
          ],
        ),
        const SizedBox(height: 8),

        // Drivers sub-card
        _SubCard(
          icon: Icons.drive_eta_outlined,
          label: 'role_driver'.tr,
          total: controller.driverTotal.value,
          color: AppColors.info,
          onTap: () => Get.to(
            () => const SupervisorCrewView(),
            binding: SupervisorCrewBinding(),
            transition: Transition.cupertino,
          ),
          stats: [
            _StatItem('lbl_available'.tr,    controller.driverAvailable.value, AppColors.success),
            _StatItem('lbl_on_trip_chip'.tr, controller.driverOnTrip.value,    AppColors.lrInTransit),
            _StatItem('status_present'.tr,   controller.driverPresent.value,   AppColors.attPresent),
          ],
        ),
        const SizedBox(height: 8),

        // Cleaners sub-card
        _SubCard(
          icon: Icons.cleaning_services_outlined,
          label: 'role_cleaner'.tr,
          total: controller.cleanerTotal.value,
          color: AppColors.lrLoaded,
          onTap: () => Get.to(
            () => const SupervisorCrewView(),
            binding: SupervisorCrewBinding(),
            transition: Transition.cupertino,
          ),
          stats: [
            _StatItem('lbl_available'.tr,    controller.cleanerAvailable.value, AppColors.success),
            _StatItem('lbl_on_trip_chip'.tr, controller.cleanerOnTrip.value,    AppColors.lrInTransit),
            _StatItem('status_present'.tr,   controller.cleanerPresent.value,   AppColors.attPresent),
          ],
        ),
        const SizedBox(height: 14),

        // ── LRs ────────────────────────────────────────────────────
        _SectionCard(
          icon: Icons.receipt_long_outlined,
          title: 'lbl_lrs'.tr,
          accentColor: AppColors.lrInTransit,
          onTap: () => Get.to(
            () => const SupervisorLrsView(),
            binding: SupervisorLrsBinding(),
            transition: Transition.cupertino,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TotalBadge(value: controller.lrTotal.value, color: AppColors.lrInTransit),
              const SizedBox(height: 12),
              _StatRow(stats: [
                _StatItem('lbl_lr_created'.tr,    controller.lrCreated.value,   AppColors.lrCreated),
                _StatItem('lbl_loaded_chip'.tr,   controller.lrLoaded.value,    AppColors.lrLoaded),
                _StatItem('status_in_transit'.tr, controller.lrInTransit.value, AppColors.lrInTransit),
                _StatItem('status_delivered'.tr,  controller.lrDelivered.value, AppColors.lrDelivered),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Attendance ─────────────────────────────────────────────
        _SectionCard(
          icon: Icons.fact_check_outlined,
          title: 'lbl_attendance_today'.tr,
          accentColor: AppColors.attPresent,
          onTap: () => _goToTab(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TotalBadge(
                  value: controller.attTotal.value,
                  color: AppColors.attPresent,
                  label: 'lbl_marked_badge'.tr),
              const SizedBox(height: 12),
              _StatRow(stats: [
                _StatItem('status_present'.tr,  controller.attPresent.value,   AppColors.attPresent),
                _StatItem('status_absent'.tr,   controller.attAbsent.value,    AppColors.attAbsent),
                _StatItem('status_half_day'.tr, controller.attHalfDay.value,   AppColors.attHalfDay),
                _StatItem('lbl_week_off'.tr,    controller.attWeeklyOff.value, AppColors.attWeeklyOff),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Vehicle Alerts ─────────────────────────────────────────
        _AlertsCard(alerts: controller.alerts),
      ],
    ));
  }
}

// ── My Attendance Quick-Action Card ───────────────────────────────────────────
class _MyAttendanceCard extends StatelessWidget {
  final SupervisorDashboardController controller;
  const _MyAttendanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rec         = controller.todayAttendance.value;
      final marked      = rec != null;
      final markLoading = controller.markLoading.value;
      final color       = marked ? AppColors.success : AppColors.warning;
      final now         = DateTime.now();
      final dayStr      = '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} ${_month(now.month)}';

      return GestureDetector(
        onTap: () => Get.to(
          () => const SupervisorMyAttendanceView(),
          binding: SupervisorMyAttendanceBinding(),
          transition: Transition.cupertino,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(
                  marked ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                  color: color, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Attendance — $dayStr',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (marked) ...[
                      Wrap(spacing: 6, children: [
                        _AttBadge(rec['attendanceTypeName'] as String? ?? ''),
                        _ApprovalBadge(rec['approvalStatus'] as String? ?? ''),
                      ]),
                    ] else
                      Text('Not marked yet',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
              if (!marked) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: markLoading
                      ? null
                      : () => _showMarkSheet(context, controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: markLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Mark', style: TextStyle(fontSize: 13)),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: AppColors.mutedText),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// ── Mark Sheet (reused from attendance module) ────────────────────────────────
void _showMarkSheet(BuildContext context, SupervisorDashboardController ctrl) {
  final remarks        = TextEditingController();
  final leaveReason    = TextEditingController();
  final selfieFile     = Rxn<File>();
  final selectedTypeId = RxnInt();
  final selectedTypeName = ''.obs;
  final selectedLeaveTypeId = RxnInt();

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
      child: Obx(() {
        final types    = ctrl.attendanceTypes.toList();
        final lTypes   = ctrl.leaveTypes.toList();
        final typeId   = selectedTypeId.value;
        final typeName = selectedTypeName.value.toLowerCase();
        final isLeave  = typeName.contains('leave');
        final loading  = ctrl.markLoading.value;

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Mark Today\'s Attendance',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(_formatToday(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),

              Text('Attendance Type *',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: types.map((t) {
                  final id     = t['id'] as int;
                  final name   = t['name'] as String? ?? '';
                  final active = typeId == id;
                  return GestureDetector(
                    onTap: loading ? null : () {
                      selectedTypeId.value   = id;
                      selectedTypeName.value = name;
                      selectedLeaveTypeId.value = null;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.navy : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.navy : AppColors.border),
                      ),
                      child: Text(name,
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.white : AppColors.bodyText,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              if (isLeave) ...[
                Text('Leave Type',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: lTypes.map((lt) {
                    final id     = lt['id'] as int;
                    final name   = lt['name'] as String? ?? '';
                    final active = selectedLeaveTypeId.value == id;
                    return GestureDetector(
                      onTap: loading ? null : () {
                        selectedLeaveTypeId.value = active ? null : id;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.navy.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppColors.navy : AppColors.border),
                        ),
                        child: Text(name,
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active ? AppColors.navy : AppColors.bodyText,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Leave Reason (Optional)',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 4),
                TextField(
                  controller: leaveReason,
                  enabled: !loading,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sick, family function…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _SelfieBox(selfieFile: selfieFile, disabled: loading),
              const SizedBox(height: 12),

              Text('Remarks (Optional)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 4),
              TextField(
                controller: remarks,
                enabled: !loading,
                decoration: InputDecoration(
                  hintText: 'Optional',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (loading || typeId == null) ? null : () async {
                    final ok = await ctrl.markAttendance(
                      typeId:      typeId,
                      leaveTypeId: selectedLeaveTypeId.value,
                      leaveReason: leaveReason.text,
                      selfieFile:  selfieFile.value,
                      remarks:     remarks.text,
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
                  icon: loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    loading ? 'Marking…' : 'Mark Attendance',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        typeId != null ? AppColors.navy : AppColors.mutedText,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
        height: 100,
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
                      size: 28, color: AppColors.mutedText),
                  const SizedBox(height: 6),
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
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Attendance Badges ─────────────────────────────────────────────────────────
class _AttBadge extends StatelessWidget {
  final String type;
  const _AttBadge(this.type);

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

class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'PENDING'  => (AppColors.warning, 'Pending'),
      'APPROVED' => (AppColors.success, 'Approved'),
      'REJECTED' => (AppColors.error,   'Rejected'),
      _          => (AppColors.mutedText, ''),
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

String _formatToday() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
}

String _weekday(int w) =>
    const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];
String _month(int m) => const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m];

// ── Section Card (tappable, full card) ────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
            color: AppColors.surface,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.bodyText,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.mutedText),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header (non-tappable label for grouped sub-cards) ─────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  const _SectionHeader({required this.icon, required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: accentColor),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.bodyText, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Sub Card (vehicle / driver / cleaner) ─────────────────────────────────────
class _SubCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int total;
  final Color color;
  final VoidCallback onTap;
  final List<_StatItem> stats;
  const _SubCard({
    required this.icon,
    required this.label,
    required this.total,
    required this.color,
    required this.onTap,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.surface,
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              // Icon + label + total
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText)),
                  Text('$total',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                ],
              ),
              const SizedBox(width: 14),
              const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
              const SizedBox(width: 14),
              // Stats
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: stats.map((s) => _MiniStat(item: s)).toList(),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Total Badge ───────────────────────────────────────────────────────────────
class _TotalBadge extends StatelessWidget {
  final int value;
  final Color color;
  final String label;
  const _TotalBadge({required this.value, required this.color, this.label = 'Total'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$value',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            )),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
  }
}

// ── Stat Row ─────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .expand((s) => [_StatCell(item: s), const SizedBox(width: 16)])
          .toList()
        ..removeLast(),
    );
  }
}

class _StatCell extends StatelessWidget {
  final _StatItem item;
  const _StatCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final cell = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.value}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: item.color,
            )),
        Text(item.label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 10)),
      ],
    );
    if (item.onTap == null) return cell;
    return GestureDetector(onTap: item.onTap, child: cell);
  }
}

class _MiniStat extends StatelessWidget {
  final _StatItem item;
  const _MiniStat({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.value}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: item.color,
            )),
        Text(item.label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText, fontSize: 9)),
      ],
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;
  const _StatItem(this.label, this.value, this.color, {this.onTap});
}

// ── Vehicle Alerts Card ───────────────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final RxList<VehicleAlert> alerts;
  const _AlertsCard({required this.alerts});

  Color _accentColor(VehicleAlert a) {
    if (a.expired)       return const Color(0xFFDC2626); // red
    if (a.daysLeft <= 7) return const Color(0xFFF97316); // orange
    return const Color(0xFFF59E0B);                       // amber
  }

  String _badge(VehicleAlert a) {
    if (a.expired)       return 'Expired';
    if (a.daysLeft == 0) return 'Today';
    return '${a.daysLeft}d left';
  }

  String _subtitle(VehicleAlert a) =>
      a.alertType == 'DOCUMENT' && a.documentName != null
          ? a.documentName!
          : a.alertType.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = alerts;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF97316)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Vehicle Document Alerts',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.bodyText, fontWeight: FontWeight.w600)),
                  ),
                  if (list.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${list.length}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309))),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Body
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 32, color: Color(0xFF22C55E)),
                    const SizedBox(height: 8),
                    Text('All vehicle documents up to date',
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length > 8 ? 8 : list.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final a = list[i];
                  final color = _accentColor(a);
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.registrationNumber,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(_subtitle(a),
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.mutedText)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(a.expiryDate,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.mutedText)),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_badge(a),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // "X more" footer
            if (list.length > 8) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('+${list.length - 8} more alerts',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ),
            ],
          ],
        ),
      );
    });
  }
}


