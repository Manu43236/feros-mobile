import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../controllers/supervisor_shell_controller.dart';

import '../../supervisor_dashboard/views/supervisor_home_tab.dart';
import '../../supervisor_orders/views/supervisor_orders_tab.dart';
import '../../supervisor_notifications/views/supervisor_notifications_view.dart';
import '../../supervisor_notifications/bindings/supervisor_notifications_binding.dart';
import '../../supervisor_profile/views/supervisor_profile_view.dart';
import '../../supervisor_profile/bindings/supervisor_profile_binding.dart';
import '../../supervisor_payslip/views/supervisor_payslip_view.dart';
import '../../supervisor_payslip/bindings/supervisor_payslip_binding.dart';
import '../../supervisor_vehicles/views/supervisor_vehicles_view.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicles_binding.dart';
import '../../supervisor_crew/views/supervisor_crew_view.dart';
import '../../supervisor_crew/bindings/supervisor_crew_binding.dart';
import '../../supervisor_active_trips/views/supervisor_active_trips_tab.dart';
import '../../supervisor_attendance/views/supervisor_attendance_tab.dart';
import '../../supervisor_lrs/views/supervisor_lrs_view.dart';
import '../../supervisor_lrs/bindings/supervisor_lrs_binding.dart';
import '../../supervisor_orders/views/supervisor_create_order_view.dart';
import '../../supervisor_breakdown/views/supervisor_breakdown_view.dart';
import '../../supervisor_breakdown/bindings/supervisor_breakdown_binding.dart';

class SupervisorShellView extends GetView<SupervisorShellController> {
  const SupervisorShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: _SupervisorDrawer(
            auth: Get.find<AuthService>(),
            controller: controller,
          ),
          appBar: _buildAppBar(),
          body: IndexedStack(
            index: controller.currentIndex.value,
            children: const [
              SupervisorHomeTab(),
              SupervisorOrdersTab(),
              SupervisorActiveTripsTab(),
              SupervisorAttendanceTab(),
            ],
          ),
          bottomNavigationBar: _SupervisorNavBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.onTabTapped,
          ),
          floatingActionButton: controller.currentIndex.value == 1
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'btn_create_order'.tr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Get.to(() => const SupervisorCreateOrderView()),
                )
              : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final auth   = Get.find<AuthService>();
    final titles = ['nav_home'.tr, 'nav_orders'.tr, 'nav_trips'.tr, 'nav_attendance'.tr];
    return AppBar(
      backgroundColor: AppColors.navy,
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
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'role_supervisor'.tr,
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
          titles[idx],
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
          if (controller.currentIndex.value != 0) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Get.to(
              () => const SupervisorNotificationsView(),
              binding: SupervisorNotificationsBinding(),
            ),
          );
        }),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'lbl_good_morning'.tr;
    if (h < 17) return 'lbl_good_afternoon'.tr;
    return 'lbl_good_evening'.tr;
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _SupervisorDrawer extends StatelessWidget {
  final AuthService auth;
  final SupervisorShellController controller;
  const _SupervisorDrawer({required this.auth, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 24,
              20,
              24,
            ),
            color: AppColors.navy,
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
                        style: AppTextStyles.bodySemiBold.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'role_supervisor'.tr,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
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

          // ── Nav tiles ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerTile(
                  icon: Icons.person_outline,
                  label: 'lbl_my_profile'.tr,
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
                  label: 'lbl_my_payslip'.tr,
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorPayslipView(),
                      binding: SupervisorPayslipBinding(),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.car_crash_outlined,
                  label: 'btn_report_breakdown'.tr,
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorBreakdownView(),
                      binding: SupervisorBreakdownBinding(),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 4),
                _DrawerSectionLabel(label: 'lbl_vehicles_billing'.tr),
                _DrawerTile(
                  icon: Icons.garage_outlined,
                  label: 'lbl_vehicles'.tr,
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorVehiclesView(),
                      binding: SupervisorVehiclesBinding(),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.badge_outlined,
                  label: 'lbl_drivers_cleaners'.tr,
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorCrewView(),
                      binding: SupervisorCrewBinding(),
                      transition: Transition.cupertino,
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'lbl_lrs'.tr,
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(
                      () => const SupervisorLrsView(),
                      binding: SupervisorLrsBinding(),
                      transition: Transition.cupertino,
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                _DrawerTile(
                  icon: Icons.logout,
                  label: 'btn_logout'.tr,
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.of(context).pop();
                    final confirmed = await FerosDialog.confirm(
                      title: 'btn_logout'.tr,
                      message: 'lbl_logout_confirm'.tr,
                      confirmText: 'btn_logout'.tr,
                      isDestructive: true,
                    );
                    if (confirmed) auth.logout();
                  },
                ),
              ],
            ),
          ),

          // ── Version ───────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'lbl_version'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Tile ───────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerTile({
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

// ── Drawer Section Label ──────────────────────────────────────────────────────
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

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _SupervisorNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _SupervisorNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home, 'nav_home'.tr),
      (Icons.assignment_outlined, Icons.assignment, 'nav_orders'.tr),
      (Icons.local_shipping_outlined, Icons.local_shipping, 'nav_trips'.tr),
      (Icons.fact_check_outlined, Icons.fact_check, 'nav_attendance'.tr),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy,
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
            final isActive = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
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
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
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
    );
  }
}

