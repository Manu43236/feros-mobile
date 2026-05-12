import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/shell_controller.dart';
import '../../dashboard/views/dashboard_view.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.navItems;
      final index = controller.currentIndex.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: index,
          children: _buildPages(items.length),
        ),
        bottomNavigationBar: _FerosNavBar(
          items: items,
          currentIndex: index,
          onTap: controller.onTabTapped,
        ),
      );
    });
  }

  List<Widget> _buildPages(int count) {
    return List.generate(count, (i) {
      if (i == 0) return const DashboardView();
      return _PlaceholderTab(index: i);
    });
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

// ── Placeholder ───────────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final int index;
  const _PlaceholderTab({required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: const Center(
        child: Text('This screen is coming in the next sprint'),
      ),
    );
  }
}
