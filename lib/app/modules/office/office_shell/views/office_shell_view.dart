import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../controllers/office_shell_controller.dart';

import '../../office_dashboard/views/office_home_tab.dart';
import '../../office_orders/views/office_orders_tab.dart';
import '../../office_vehicles/views/office_vehicles_tab.dart';
import '../../office_clients/views/office_clients_view.dart';
import '../../office_finance/views/office_finance_view.dart';
import '../../office_staff/views/office_staff_view.dart';
import '../../office_attendance/views/office_attendance_view.dart';
import '../../office_payroll/views/office_payroll_view.dart';
import '../../office_inventory/views/office_inventory_view.dart';
import '../../office_subscription/views/office_subscription_view.dart';
import '../../office_notifications/views/office_notifications_view.dart';
import '../../office_notifications/bindings/office_notifications_binding.dart';

// Profile / payslip
import '../../../supervisor/supervisor_profile/views/supervisor_profile_view.dart';
import '../../../supervisor/supervisor_payslip/views/supervisor_payslip_view.dart';
import '../../../supervisor/supervisor_payslip/bindings/supervisor_payslip_binding.dart';

// Fuel log + Meter reading + LRs
import '../../../supervisor/supervisor_fuel_log/views/supervisor_fuel_log_view.dart';
import '../../../supervisor/supervisor_fuel_log/bindings/supervisor_fuel_log_binding.dart';
import '../../../supervisor/supervisor_meter_reading/views/supervisor_meter_reading_view.dart';
import '../../../supervisor/supervisor_meter_reading/bindings/supervisor_meter_reading_binding.dart';
import '../../../supervisor/supervisor_lrs/views/supervisor_lrs_view.dart';
import '../../../supervisor/supervisor_lrs/bindings/supervisor_lrs_binding.dart';

class OfficeShellView extends GetView<OfficeShellController> {
  const OfficeShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _OfficeDrawer(
          auth: Get.find<AuthService>(),
          controller: controller,
        ),
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            OfficeHomeTab(),
            OfficeOrdersTab(),
            OfficeVehiclesTab(),
            SupervisorProfileView(),
          ],
        ),
        bottomNavigationBar: _OfficeNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.onTabTapped,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final auth   = Get.find<AuthService>();
    final titles = ['Home', 'Orders', 'Vehicles', 'Profile'];
    final role   = auth.user?.role ?? '';
    final roleLabel = role == 'ADMIN' ? 'Admin' : 'Office Staff';

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
                      roleLabel,
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
        Obx(() => _NotifBell(
          count: controller.unreadCount.value,
          onTap: () async {
            await Get.to(
              () => const OfficeNotificationsView(),
              binding: OfficeNotificationsBinding(),
            );
            controller.clearUnreadCount();
          },
        )),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _OfficeDrawer extends StatelessWidget {
  final AuthService auth;
  final OfficeShellController controller;
  const _OfficeDrawer({required this.auth, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user    = auth.user;
    final role    = user?.role ?? '';
    final isAdmin = role == 'ADMIN';
    final roleLabel = isAdmin ? 'Admin' : 'Office Staff';

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
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          roleLabel,
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

          // ── Nav Tiles ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (!isAdmin)
                  _DrawerTile(
                    icon: Icons.payments_outlined,
                    label: 'My Payslip',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const SupervisorPayslipView(), binding: SupervisorPayslipBinding());
                    },
                  ),
                const _DrawerSectionLabel('Operations'),
                _DrawerTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoices',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeFinanceView()); },
                ),
                _DrawerTile(
                  icon: Icons.description_outlined,
                  label: 'LR Register',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const SupervisorLrsView(), binding: SupervisorLrsBinding()); },
                ),
                _DrawerTile(
                  icon: Icons.business_outlined,
                  label: 'Clients',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeClientsView()); },
                ),
                _DrawerTile(
                  icon: Icons.badge_outlined,
                  label: 'Staff',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeStaffView()); },
                ),
                _DrawerTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeInventoryView()); },
                ),
                _DrawerTile(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeAttendanceView()); },
                ),
                _DrawerTile(
                  icon: Icons.payments_outlined,
                  label: 'Payroll',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficePayrollView()); },
                ),
                const _DrawerSectionLabel('Vehicles'),
                _DrawerTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Fuel Log',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const SupervisorFuelLogView(), binding: SupervisorFuelLogBinding()); },
                ),
                _DrawerTile(
                  icon: Icons.speed_outlined,
                  label: 'Meter Reading',
                  onTap: () { Navigator.of(context).pop(); Get.to(() => const SupervisorMeterReadingView(), binding: SupervisorMeterReadingBinding()); },
                ),
                if (isAdmin) ...[
                  const _DrawerSectionLabel('Admin'),
                  _DrawerTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Subscription',
                    onTap: () { Navigator.of(context).pop(); Get.to(() => const OfficeSubscriptionView()); },
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

          // ── Version ───────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'FEROS v1.0.0',
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

// ── Drawer Section Label ──────────────────────────────────────────────────────
class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.mutedText,
          letterSpacing: 0.8,
        ),
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

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _OfficeNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _OfficeNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_outlined,       Icons.dashboard,       'Home'),
      (Icons.assignment_outlined,      Icons.assignment,      'Orders'),
      (Icons.local_shipping_outlined,  Icons.local_shipping,  'Vehicles'),
      (Icons.person_outline,            Icons.person,          'Profile'),
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
    );
  }
}

// ── Notification Bell with Badge ──────────────────────────────────────────────
class _NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Placeholder Tab ───────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text('Coming soon',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
