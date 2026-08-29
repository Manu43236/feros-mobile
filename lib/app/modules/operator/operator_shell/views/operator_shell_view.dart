import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../driver/driver_attendance/views/driver_attendance_view.dart';
import '../../../driver/driver_profile/views/driver_profile_view.dart';
import '../../../supervisor/supervisor_payslip/views/supervisor_payslip_view.dart';
import '../../operator_dashboard/views/operator_dashboard_view.dart';
import '../controllers/operator_shell_controller.dart';

class OperatorShellView extends GetView<OperatorShellController> {
  const OperatorShellView({super.key});

  static const _tabs = [
    _TabItem(label: 'Home',       icon: Icons.construction_outlined,  activeIcon: Icons.construction),
    _TabItem(label: 'Attendance', icon: Icons.check_circle_outline,   activeIcon: Icons.check_circle),
    _TabItem(label: 'Payslip',    icon: Icons.receipt_outlined,       activeIcon: Icons.receipt),
    _TabItem(label: 'Profile',    icon: Icons.person_outline,         activeIcon: Icons.person),
  ];

  static const _pages = [
    OperatorDashboardView(),
    _AttendancePage(),
    _PayslipPage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(index),
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: _OperatorNavBar(
          tabs: _tabs,
          currentIndex: index,
          onTap: controller.onTabTapped,
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(int index) {
    final auth = Get.find<AuthService>();
    return AppBar(
      backgroundColor: AppColors.equipSidebar,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          child: Text(
            FerosStringUtils.initials(auth.user?.name ?? ''),
            style: AppTextStyles.bodySemiBold.copyWith(
              color: Colors.white, fontSize: 12),
          ),
        ),
      ),
      title: index == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.7)),
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
                        'Operator',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              _tabs[index].label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Nav Bar ───────────────────────────────────────────────────────────────────
class _OperatorNavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final void Function(int) onTap;

  const _OperatorNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          children: List.generate(tabs.length, (i) {
            final tab      = tabs[i];
            final isActive = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 3,
                      width: isActive ? 32 : 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      size: isActive ? 24 : 22,
                      color: isActive
                          ? AppColors.orange
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: AppTextStyles.navLabel.copyWith(
                        color: isActive
                            ? AppColors.orange
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

// ── Tab model ─────────────────────────────────────────────────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem({required this.label, required this.icon, required this.activeIcon});
}

// ── Wrapper pages (needed for IndexedStack with existing views) ───────────────
class _AttendancePage extends StatelessWidget {
  const _AttendancePage();
  @override
  Widget build(BuildContext context) => DriverAttendanceView();
}

class _PayslipPage extends StatelessWidget {
  const _PayslipPage();
  @override
  Widget build(BuildContext context) => const SupervisorPayslipView(showAppBar: false);
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => const DriverProfileView();
}
