import 'package:feros/core/popups/feros_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../controllers/supervisor_shell_controller.dart';

// ── Tab bodies (placeholders until each sprint step builds them) ──────────────
import '../../dashboard/views/supervisor_home_tab.dart';
import '../../../notifications/views/notifications_view.dart';
import '../../../profile/views/profile_view.dart';
import '../../../payslip/views/payslip_view.dart';
import '../../../fuel_log/views/fuel_log_view.dart';
import '../../../breakdown/views/breakdown_view.dart';

class SupervisorShellView extends StatefulWidget {
  const SupervisorShellView({super.key});

  @override
  State<SupervisorShellView> createState() => _SupervisorShellViewState();
}

class _SupervisorShellViewState extends State<SupervisorShellView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final SupervisorShellController _ctrl;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(SupervisorShellController());
    _auth = Get.find<AuthService>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _SupervisorDrawer(auth: _auth, ctrl: _ctrl),
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: _ctrl.currentIndex.value,
          children: const [
            SupervisorHomeTab(),
            _ComingSoon(
              label: 'Orders',
              icon: Icons.assignment_outlined,
              sprint: 3,
            ),
            _ComingSoon(
              label: 'Trips',
              icon: Icons.local_shipping_outlined,
              sprint: 3,
            ),
            _ComingSoon(
              label: 'Attendance',
              icon: Icons.fact_check_outlined,
              sprint: 3,
            ),
          ],
        ),
        bottomNavigationBar: _SupervisorNavBar(
          currentIndex: _ctrl.currentIndex.value,
          onTap: _ctrl.onTabTapped,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Home', 'Orders', 'Trips', 'Attendance'];
    return AppBar(
      backgroundColor: AppColors.navy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () {
          FerosSnackbar.success(
            'DRAWER OPENED This is where the drawer would open',
          );
          // print("APP icon clicked - opening drawer");
          // Scaffold.of(context).openDrawer();
        },
        icon: CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            FerosStringUtils.initials(_auth.user?.name ?? ''),
            style: AppTextStyles.bodySemiBold.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Obx(() {
        final idx = _ctrl.currentIndex.value;
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
              Text(
                _auth.user?.name ?? '',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
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
        // Unread notification dot handled inside NotificationsView
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => Get.to(() => const NotificationsView()),
        ),
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
class _SupervisorDrawer extends StatelessWidget {
  final AuthService auth;
  final SupervisorShellController ctrl;
  const _SupervisorDrawer({required this.auth, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header (extends behind status bar) ────────────────────
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
                          'Supervisor',
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

          // ── Nav tiles ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerTile(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const ProfileView());
                  },
                ),
                _DrawerTile(
                  icon: Icons.payments_outlined,
                  label: 'My Payslip',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const PayslipView());
                  },
                ),
                _DrawerTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'My Attendance',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO Sprint 3 Step 6
                    Get.snackbar(
                      'Coming Soon',
                      'My Attendance will be available shortly',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Fuel Log',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const FuelLogView());
                  },
                ),
                _DrawerTile(
                  icon: Icons.car_crash_outlined,
                  label: 'Breakdowns',
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const BreakdownView());
                  },
                ),
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

          // ── Version ───────────────────────────────────────────────
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
class _SupervisorNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _SupervisorNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.assignment_outlined, Icons.assignment, 'Orders'),
      (Icons.local_shipping_outlined, Icons.local_shipping, 'Trips'),
      (Icons.fact_check_outlined, Icons.fact_check, 'Attendance'),
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
            final item = items[i];
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

// ── Coming Soon placeholder ───────────────────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  final String label;
  final IconData icon;
  final int sprint;
  const _ComingSoon({
    required this.label,
    required this.icon,
    required this.sprint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.heading3.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in Sprint $sprint step',
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
