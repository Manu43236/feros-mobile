import 'package:flutter/material.dart';
import 'package:get/get.dart';
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


