import 'package:feros/app/modules/driver/driver_dashboard/views/driver_dashboard_view.dart';
import 'package:feros/app/modules/driver/driver_shell/controllers/driver_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../driver_trips/views/driver_trips_view.dart';
import '../../driver_attendance/views/driver_attendance_view.dart';
import '../../driver_profile/views/driver_profile_view.dart';
import '../../../../../core/services/auth_service.dart';

class DriverShellView extends GetView<DriverShellController> {
  const DriverShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.navItems;
      final index = controller.currentIndex.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: index,
          children: _buildPages(),
        ),
        bottomNavigationBar: _FerosNavBar(
          items: items,
          currentIndex: index,
          onTap: controller.onTabTapped,
        ),
      );
    });
  }

  List<Widget> _buildPages() {
    final role = Get.find<AuthService>().user?.role ?? '';
    switch (role) {
      case 'DRIVER':
      case 'CLEANER':
        return [
          const DriverDashboardView(),
           DriverTripsView(),
           DriverAttendanceView(),
          const DriverProfileView(),
        ];
      case 'SUPERVISOR':
        return [
          const DriverDashboardView(),
          _ComingSoonTab(title: 'Orders', icon: Icons.assignment_outlined,         sprint: 3),
          _ComingSoonTab(title: 'Staff',  icon: Icons.group_outlined,              sprint: 3),
          const DriverProfileView(),
        ];
      case 'OFFICE_STAFF':
        return [
          const DriverDashboardView(),
          _ComingSoonTab(title: 'Orders', icon: Icons.assignment_outlined,         sprint: 5),
          _ComingSoonTab(title: 'LRs',    icon: Icons.receipt_long_outlined,       sprint: 5),
          const DriverProfileView(),
        ];
      case 'SERVICE_MEN':
        return [
          const DriverDashboardView(),
          _ComingSoonTab(title: 'Services',  icon: Icons.build_outlined,           sprint: 4),
          _ComingSoonTab(title: 'Breakdown', icon: Icons.car_crash_outlined,       sprint: 4),
          const DriverProfileView(),
        ];
      case 'STORE_KEEPER':
        return [
          const DriverDashboardView(),
          _ComingSoonTab(title: 'Inventory', icon: Icons.inventory_2_outlined,     sprint: 4),
          _ComingSoonTab(title: 'Requests',  icon: Icons.list_alt_outlined,        sprint: 4),
          const DriverProfileView(),
        ];
      default: // ADMIN
        return [
          const DriverDashboardView(),
          _ComingSoonTab(title: 'Orders',   icon: Icons.assignment_outlined,       sprint: 6),
          _ComingSoonTab(title: 'Vehicles', icon: Icons.directions_bus_outlined,   sprint: 6),
          const DriverProfileView(),
        ];
    }
  }
}

// ── Modern Navy Bottom Nav ────────────────────────────────────────────────────
class _FerosNavBar extends StatelessWidget {
  final List items;
  final int currentIndex;
  final void Function(int) onTap;

  const _FerosNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            final item = items[i];
            final isActive = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active indicator line at top
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 3,
                      width: isActive ? 32 : 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: isActive ? 24 : 22,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
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

// ── Coming Soon Tab ───────────────────────────────────────────────────────────
class _ComingSoonTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final int sprint;
  const _ComingSoonTab({required this.title, required this.icon, required this.sprint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.mutedText),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Coming in Sprint $sprint',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}
