import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../controllers/supervisor_dashboard_controller.dart';
import '../../supervisor_shell/controllers/supervisor_shell_controller.dart';
import '../../supervisor_vehicles/views/supervisor_vehicles_view.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicles_binding.dart';
import '../../supervisor_crew/views/supervisor_crew_view.dart';
import '../../supervisor_crew/bindings/supervisor_crew_binding.dart';
import '../../supervisor_lrs/views/supervisor_lrs_view.dart';
import '../../supervisor_lrs/bindings/supervisor_lrs_binding.dart';

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

        // ── Self Attendance ────────────────────────────────────────
        _SelfAttendanceCard(controller: controller),
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
                _StatItem('status_active'.tr,    controller.orderActive.value,    AppColors.orderActive),
                _StatItem('status_pending'.tr,   controller.orderPending.value,   AppColors.orderPending),
                _StatItem('status_completed'.tr, controller.orderCompleted.value, AppColors.orderCompleted),
                _StatItem('status_delivered'.tr, controller.orderDelivered.value, AppColors.lrDelivered),
                _StatItem('status_cancelled'.tr, controller.orderCancelled.value, AppColors.orderCancelled),
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
      ],
    ));
  }
}

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
    return Column(
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
  const _StatItem(this.label, this.value, this.color);
}

// ── Helpers shared by card + sheet ────────────────────────────────────────────
Color _attTypeColor(String name) {
  final n = name.toUpperCase();
  if (n.contains('PRESENT') && !n.contains('HALF')) return AppColors.attPresent;
  if (n.contains('ABSENT'))  return AppColors.attAbsent;
  if (n.contains('HALF'))    return AppColors.attHalfDay;
  if (n.contains('LEAVE'))   return AppColors.attLeave;
  if (n.contains('HOLIDAY')) return AppColors.attHoliday;
  if (n.contains('WEEK') || n.contains('OFF')) return AppColors.attWeeklyOff;
  return AppColors.mutedText;
}

String _attTypeLabel(String name) {
  final n = name.toUpperCase();
  if (n.contains('PRESENT') && !n.contains('HALF')) return 'status_present'.tr;
  if (n.contains('ABSENT'))  return 'status_absent'.tr;
  if (n.contains('HALF'))    return 'status_half_day'.tr;
  if (n.contains('LEAVE'))   return 'status_leave'.tr;
  if (n.contains('HOLIDAY')) return 'lbl_holiday'.tr;
  if (n.contains('WEEK') || n.contains('OFF')) return 'lbl_week_off'.tr;
  return name.split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ── Self Attendance Card ───────────────────────────────────────────────────────
class _SelfAttendanceCard extends StatelessWidget {
  final SupervisorDashboardController controller;
  const _SelfAttendanceCard({required this.controller});

  void _openSheet(BuildContext context, Map<String, dynamic> t) {
    final tid    = t['id'];
    final typeId = tid is int ? tid : int.tryParse(tid.toString()) ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelfieSheet(
        typeId: typeId,
        typeName: t['name'] as String? ?? '',
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final marked    = controller.selfAttendance.value;
      final types     = controller.attendanceTypes;
      final isMarking = controller.isSelfMarking.value;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
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
                    color: AppColors.attPresent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_pin_circle_outlined,
                      size: 16, color: AppColors.attPresent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('lbl_my_attendance'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.bodyText,
                          fontWeight: FontWeight.w600)),
                ),
                Text('lbl_today'.tr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            if (marked != null) ...[
              // Already marked — show type + approval status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _attTypeColor(marked['attendanceTypeName'] as String? ?? '')
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _attTypeLabel(marked['attendanceTypeName'] as String? ?? ''),
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                        color: _attTypeColor(marked['attendanceTypeName'] as String? ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ApprovalBadge(
                      status: marked['approvalStatus'] as String? ?? 'PENDING'),
                ],
              ),
            ] else if (isMarking) ...[
              const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                ),
              ),
            ] else ...[
              Text('lbl_tap_mark_att'.tr,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  final tName = t['name'] as String? ?? '';
                  final color = _attTypeColor(tName);
                  return GestureDetector(
                    onTap: () => _openSheet(context, t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        _attTypeLabel(tName),
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12,
                          fontWeight: FontWeight.w500, color: color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Approval Badge ─────────────────────────────────────────────────────────────
class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending  = status == 'PENDING';
    final isApproved = status == 'APPROVED';
    final color = isPending ? AppColors.warning : isApproved
        ? AppColors.attPresent : AppColors.error;
    final icon  = isPending ? Icons.hourglass_top_rounded
        : isApproved ? Icons.check_circle_outline : Icons.cancel_outlined;
    final label = isPending ? 'lbl_pending_approval'.tr : isApproved ? 'status_approved'.tr : 'status_rejected'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 10,
                fontWeight: FontWeight.w600, color: color,
              )),
        ],
      ),
    );
  }
}

// ── Selfie + Location Sheet ────────────────────────────────────────────────────
class _SelfieSheet extends StatefulWidget {
  final int typeId;
  final String typeName;
  final SupervisorDashboardController controller;
  const _SelfieSheet({
    required this.typeId,
    required this.typeName,
    required this.controller,
  });

  @override
  State<_SelfieSheet> createState() => _SelfieSheetState();
}

class _SelfieSheetState extends State<_SelfieSheet> {
  XFile?    _selfie;
  Position? _position;
  bool      _locating   = false;
  bool      _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locating = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() { _position = pos; _locating = false; });
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _takeSelfie() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );
    if (img != null && mounted) setState(() => _selfie = img);
  }

  Future<void> _submit() async {
    if (_selfie == null) return;
    setState(() => _submitting = true);
    final ok = await widget.controller.markSelf(
      widget.typeId,
      filePath: _selfie!.path,
      latitude:  _position?.latitude,
      longitude: _position?.longitude,
    );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _attTypeColor(widget.typeName);
    final typeLabel = _attTypeLabel(widget.typeName);
    final canSubmit = _selfie != null && !_submitting;

    return Container(
      margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('lbl_mark_attendance'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.bodyText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(typeLabel,
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12,
                        fontWeight: FontWeight.w600, color: typeColor,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selfie section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _takeSelfie,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selfie != null ? typeColor : AppColors.border,
                    width: _selfie != null ? 2 : 1,
                  ),
                ),
                child: _selfie != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(File(_selfie!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 36, color: AppColors.mutedText),
                          const SizedBox(height: 8),
                          Text('lbl_take_selfie'.tr,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mutedText)),
                          const SizedBox(height: 4),
                          Text('lbl_required_hint'.tr,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.hintText)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Location status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _locating
                        ? Icons.gps_not_fixed
                        : _position != null
                            ? Icons.gps_fixed
                            : Icons.location_off_outlined,
                    size: 16,
                    color: _locating
                        ? AppColors.warning
                        : _position != null
                            ? AppColors.attPresent
                            : AppColors.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locating
                          ? 'lbl_getting_location'.tr
                          : _position != null
                              ? '${_position!.latitude.toStringAsFixed(5)}, '
                                '${_position!.longitude.toStringAsFixed(5)}'
                              : 'lbl_location_unavailable'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: _position != null
                            ? AppColors.bodyText
                            : AppColors.mutedText,
                      ),
                    ),
                  ),
                  if (!_locating && _position == null)
                    GestureDetector(
                      onTap: _fetchLocation,
                      child: Text('btn_retry'.tr,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  disabledBackgroundColor:
                      AppColors.navy.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('btn_submit_attendance'.tr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
