import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../controllers/supervisor_equipment_shell_controller.dart';
import '../../work_orders/controllers/equip_work_orders_controller.dart';
import '../../attendance/controllers/equip_attendance_controller.dart';
import '../../breakdown/controllers/equip_breakdown_controller.dart';
import '../../breakdown/views/equip_breakdown_view.dart';

class EquipHomeTab extends StatelessWidget {
  const EquipHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<SupervisorEquipmentShellController>();

    return RefreshIndicator(
      color: AppColors.equipSidebar,
      onRefresh: () async {
        if (shell.canAccessEquipment) {
          await Get.find<EquipWorkOrdersController>().fetchAll();
          await Get.find<EquipAttendanceController>().fetchAll();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Stats section ────────────────────────────────────
          if (shell.canAccessEquipment) ...[
            Text(
              'Overview',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _WorkOrderStatsRow(),
            const SizedBox(height: 10),
            _AttendanceStatsRow(),
            const SizedBox(height: 24),
          ],

          // ── Quick actions ────────────────────────────────────
          Text(
            'Quick Actions',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (shell.canAccessEquipment) ...[
            _QuickAction(
              icon: Icons.construction_outlined,
              label: 'Work Orders',
              subtitle: 'View & manage machine sessions',
              onTap: () => shell.currentIndex.value =
                  shell.bothEnabled ? 1 : 1,
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.fact_check_outlined,
              label: 'Operator Attendance',
              subtitle: 'Mark today\'s operator attendance',
              onTap: () => shell.currentIndex.value =
                  shell.bothEnabled ? 3 : 2,
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.car_crash_outlined,
              label: 'Report Breakdown',
              subtitle: 'Report a machine breakdown',
              color: AppColors.error,
              onTap: () => Get.to(
                () => const EquipBreakdownView(),
                binding: BindingsBuilder(
                    () { Get.put(EquipBreakdownController()); }),
              ),
            ),
          ],

          if (shell.canAccessLeases) ...[
            if (shell.canAccessEquipment) const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.key_outlined,
              label: 'Vehicle Leases',
              subtitle: 'View lease vehicles & sessions',
              onTap: () => shell.currentIndex.value =
                  shell.bothEnabled ? 2 : 1,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Work Order Stats ──────────────────────────────────────────────────────────
class _WorkOrderStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EquipWorkOrdersController>();
    return Obx(() {
      final wos        = ctrl.workOrders;
      final active     = wos.where((w) => w['status'] == 'IN_PROGRESS').length;
      final confirmed  = wos.where((w) => w['status'] == 'CONFIRMED').length;
      final machines   = wos
          .where((w) => w['status'] == 'IN_PROGRESS')
          .fold<int>(0, (sum, w) => sum + ((w['machineCount'] as int?) ?? 0));

      return Row(
        children: [
          _StatTile(
              icon: Icons.construction_outlined,
              label: 'Active WOs',
              value: active.toString(),
              color: AppColors.equipSidebar),
          const SizedBox(width: 10),
          _StatTile(
              icon: Icons.pending_outlined,
              label: 'Confirmed',
              value: confirmed.toString(),
              color: AppColors.info),
          const SizedBox(width: 10),
          _StatTile(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Machines',
              value: machines.toString(),
              color: AppColors.success),
        ],
      );
    });
  }
}

// ── Attendance Stats ──────────────────────────────────────────────────────────
class _AttendanceStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EquipAttendanceController>();
    return Obx(() => Row(
          children: [
            _StatTile(
                icon: Icons.check_circle_outlined,
                label: 'Present',
                value: ctrl.present.toString(),
                color: AppColors.success),
            const SizedBox(width: 10),
            _StatTile(
                icon: Icons.cancel_outlined,
                label: 'Absent',
                value: ctrl.absent.toString(),
                color: AppColors.error),
            const SizedBox(width: 10),
            _StatTile(
                icon: Icons.help_outline,
                label: 'Unmarked',
                value: ctrl.unmarked.toString(),
                color: AppColors.mutedText),
          ],
        ));
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.heading3.copyWith(
                    color: color, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.equipSidebar;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
