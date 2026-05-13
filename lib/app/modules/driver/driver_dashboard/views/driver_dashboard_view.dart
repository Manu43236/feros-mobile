import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../../../../routes/app_pages.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import 'driver_dashboard.dart';
import '../../../supervisor/dashboard/views/supervisor_dashboard.dart';

class DriverDashboardView extends StatelessWidget {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: DashboardController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(controller),
        body: Obx(() {
          if (controller.state.value == ViewState.loading) {
            return const ShimmerList(count: 4);
          }
          return RefreshIndicator(
            onRefresh: controller.fetchDashboard,
            color: AppColors.navy,
            child: _buildBody(controller),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DashboardController controller) {
    return AppBar(
      backgroundColor: AppColors.navy,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Obx(() => Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              FerosStringUtils.initials(controller.userName),
              style: AppTextStyles.bodySemiBold.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.greeting,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  controller.userName,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              controller.roleLabel,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      )),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
            ),
            Obx(() => controller.unreadNotifications.value > 0
                ? Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(DashboardController controller) {
    final role = Get.find<AuthService>().user?.role ?? '';
    switch (role) {
      case 'DRIVER':
      case 'CLEANER':
        return DriverDashboard(controller: controller);
      case 'SUPERVISOR':
        return SupervisorDashboard(controller: controller);
      case 'OFFICE_STAFF':
        return OfficeDashboard(controller: controller);
      case 'SERVICE_MEN':
        return ServiceMenDashboard(controller: controller);
      case 'STORE_KEEPER':
        return StoreKeeperDashboard(controller: controller);
      default: // ADMIN
        return AdminDashboard(controller: controller);
    }
  }
}
