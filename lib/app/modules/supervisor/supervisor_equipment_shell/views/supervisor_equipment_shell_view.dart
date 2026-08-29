import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../controllers/supervisor_equipment_shell_controller.dart';
import '../work_orders/views/equip_work_orders_tab.dart';
import '../attendance/views/equip_attendance_tab.dart';
import '../breakdown/controllers/equip_breakdown_controller.dart';
import '../breakdown/views/equip_breakdown_view.dart';
import '../leases/views/equip_leases_tab.dart';
import '../home/views/equip_home_tab.dart';

import '../../../supervisor/supervisor_profile/views/supervisor_profile_view.dart';
import '../../../supervisor/supervisor_profile/bindings/supervisor_profile_binding.dart';
import '../../../supervisor/supervisor_payslip/views/supervisor_payslip_view.dart';
import '../../../supervisor/supervisor_payslip/bindings/supervisor_payslip_binding.dart';
import '../../../supervisor/supervisor_my_attendance/views/supervisor_my_attendance_view.dart';
import '../../../supervisor/supervisor_my_attendance/bindings/supervisor_my_attendance_binding.dart';
import '../../../supervisor/supervisor_notifications/views/supervisor_notifications_view.dart';
import '../../../supervisor/supervisor_notifications/bindings/supervisor_notifications_binding.dart';

class SupervisorEquipmentShellView
    extends GetView<SupervisorEquipmentShellController> {
  const SupervisorEquipmentShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.currentIndex.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.currentIndex.value = 0;
        },
        child: Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: _EquipmentDrawer(
            auth: Get.find<AuthService>(),
            controller: controller,
          ),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              if (Get.find<AuthService>().user?.canAccessVehicles ?? false)
                ColoredBox(
                  color: AppColors.equipSidebar,
                  child: const _ShellToggle(isVehicleShell: false),
                ),
              Expanded(
                child: IndexedStack(
                  index: controller.currentIndex.value,
                  children: _buildTabs(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _EquipmentNavBar(
            controller: controller,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabs() {
    const equipTab  = EquipWorkOrdersTab();
    const leasesTab = EquipLeasesTab();
    const attTab    = EquipAttendanceTab();
    const homeTab   = EquipHomeTab();
    final moreTab   = _MoreTab(controller: controller);

    if (controller.bothEnabled) {
      // Home / Work Orders / Leases / Attendance
      return [homeTab, equipTab, leasesTab, attTab];
    } else if (controller.canAccessEquipment) {
      // Home / Work Orders / Attendance / More
      return [homeTab, equipTab, attTab, moreTab];
    } else {
      // Home / Leases / Attendance / More
      return [homeTab, leasesTab, attTab, moreTab];
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final auth = Get.find<AuthService>();
    return AppBar(
      backgroundColor: AppColors.equipSidebar,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: controller.openDrawer,
        icon: CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            FerosStringUtils.initials(auth.user?.name ?? ''),
            style: AppTextStyles.bodySemiBold.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Obx(() {
        final idx = controller.currentIndex.value;
        if (idx == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      auth.user?.name ?? '',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Supervisor',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Text(
          _tabTitle(idx),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        );
      }),
      actions: [
        Obx(() {
          if (controller.currentIndex.value != 0) {
            return const SizedBox.shrink();
          }
          return IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () => Get.to(
              () => const SupervisorNotificationsView(),
              binding: SupervisorNotificationsBinding(),
            ),
          );
        }),
      ],
    );
  }

  String _tabTitle(int idx) {
    if (controller.bothEnabled) {
      const titles = ['Home', 'Work Orders', 'Leases', 'Attendance'];
      return titles[idx];
    } else if (controller.canAccessEquipment) {
      const titles = ['Home', 'Work Orders', 'Attendance', 'More'];
      return titles[idx];
    } else {
      const titles = ['Home', 'Leases', 'Attendance', 'More'];
      return titles[idx];
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── More Tab ──────────────────────────────────────────────────────────────────
// Shown as 4th tab when only one module is enabled (equipment-only or leases-only)
class _MoreTab extends StatelessWidget {
  final SupervisorEquipmentShellController controller;
  const _MoreTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _MoreTile(
          icon: Icons.person_outline,
          label: 'My Profile',
          onTap: () => Get.to(
            () => const SupervisorProfileView(),
            binding: SupervisorProfileBinding(),
          ),
        ),
        _MoreTile(
          icon: Icons.payments_outlined,
          label: 'My Payslip',
          onTap: () => Get.to(
            () => const SupervisorPayslipView(),
            binding: SupervisorPayslipBinding(),
          ),
        ),
        _MoreTile(
          icon: Icons.fact_check_outlined,
          label: 'My Attendance',
          onTap: () => Get.to(
            () => const SupervisorMyAttendanceView(),
            binding: SupervisorMyAttendanceBinding(),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _MoreTile(
          icon: Icons.logout,
          label: 'Logout',
          color: AppColors.error,
          onTap: () async {
            final confirmed = await FerosDialog.confirm(
              title: 'Logout',
              message: 'Are you sure you want to logout?',
              confirmText: 'Logout',
              isDestructive: true,
            );
            if (confirmed) auth.logout();
          },
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.bodyText;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTextStyles.body.copyWith(color: c)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 24,
    );
  }
}

// ── Shell Toggle ──────────────────────────────────────────────────────────────
class _ShellToggle extends StatelessWidget {
  final bool isVehicleShell;
  const _ShellToggle({required this.isVehicleShell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seg(
              icon: Icons.local_shipping_outlined,
              label: 'Vehicles',
              active: isVehicleShell,
              activeColor: AppColors.equipSidebar,
              onTap: isVehicleShell
                  ? null
                  : () => Get.offAllNamed('/supervisor'),
            ),
            _seg(
              icon: Icons.construction_outlined,
              label: 'Equipment',
              active: !isVehicleShell,
              activeColor: AppColors.equipSidebar,
              onTap: !isVehicleShell
                  ? null
                  : () => Get.offAllNamed('/supervisor/equipment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? activeColor : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _EquipmentDrawer extends StatelessWidget {
  final AuthService auth;
  final SupervisorEquipmentShellController controller;
  const _EquipmentDrawer(
      {required this.auth, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 24,
              20,
              24,
            ),
            color: AppColors.equipSidebar,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    FerosStringUtils.initials(user?.name ?? ''),
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '—',
                        style: AppTextStyles.bodySemiBold
                            .copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Supervisor',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.companyName ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nav tiles ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerTile(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorProfileView(),
                      binding: SupervisorProfileBinding(),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.payments_outlined,
                  label: 'My Payslip',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorPayslipView(),
                      binding: SupervisorPayslipBinding(),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.fact_check_outlined,
                  label: 'My Attendance',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorMyAttendanceView(),
                      binding: SupervisorMyAttendanceBinding(),
                    );
                  },
                ),
                if (controller.canAccessEquipment) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 4),
                  _DrawerSectionLabel(label: 'Equipment'),
                  _DrawerTile(
                    icon: Icons.construction_outlined,
                    label: 'Work Orders',
                    onTap: () {
                      Navigator.of(context).pop();
                      controller.currentIndex.value =
                          controller.bothEnabled ? 1 : 1;
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.car_crash_outlined,
                    label: 'Report Breakdown',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(
                        () => const EquipBreakdownView(),
                        binding: BindingsBuilder(
                            () { Get.put(EquipBreakdownController()); }),
                      );
                    },
                  ),
                ],
                if (controller.canAccessLeases) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 4),
                  _DrawerSectionLabel(label: 'Leases'),
                  _DrawerTile(
                    icon: Icons.key_outlined,
                    label: 'Vehicle Leases',
                    onTap: () {
                      Navigator.of(context).pop();
                      controller.currentIndex.value =
                          controller.bothEnabled ? 2 : 1;
                    },
                  ),
                ],
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                _DrawerTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.of(context).pop();
                    final confirmed = await FerosDialog.confirm(
                      title: 'Logout',
                      message: 'Are you sure you want to logout?',
                      confirmText: 'Logout',
                      isDestructive: true,
                    );
                    if (confirmed) auth.logout();
                  },
                ),
              ],
            ),
          ),

          // ── Version ─────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'lbl_version'.tr,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _EquipmentNavBar extends StatelessWidget {
  final SupervisorEquipmentShellController controller;
  const _EquipmentNavBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = _navItems(controller);
    return Obx(
      () => Container(
        decoration: const BoxDecoration(
          color: AppColors.equipSidebar,
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final isActive = i == controller.currentIndex.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 3,
                        width: isActive ? 28 : 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(
                        isActive ? item.$2 : item.$1,
                        size: isActive ? 24 : 22,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: AppTextStyles.navLabel.copyWith(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<(IconData, IconData, String)> _navItems(
      SupervisorEquipmentShellController c) {
    if (c.bothEnabled) {
      return [
        (Icons.home_outlined,          Icons.home,               'Home'),
        (Icons.construction_outlined,  Icons.construction,       'Work Orders'),
        (Icons.key_outlined,           Icons.key,                'Leases'),
        (Icons.fact_check_outlined,    Icons.fact_check,         'Attendance'),
      ];
    } else if (c.canAccessEquipment) {
      return [
        (Icons.home_outlined,          Icons.home,               'Home'),
        (Icons.construction_outlined,  Icons.construction,       'Work Orders'),
        (Icons.fact_check_outlined,    Icons.fact_check,         'Attendance'),
        (Icons.more_horiz_outlined,    Icons.more_horiz,         'More'),
      ];
    } else {
      return [
        (Icons.home_outlined,          Icons.home,               'Home'),
        (Icons.key_outlined,           Icons.key,                'Leases'),
        (Icons.fact_check_outlined,    Icons.fact_check,         'Attendance'),
        (Icons.more_horiz_outlined,    Icons.more_horiz,         'More'),
      ];
    }
  }
}

// ── Drawer helpers ────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.bodyText;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTextStyles.body.copyWith(color: c)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 24,
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 10,
        ),
      ),
    );
  }
}
