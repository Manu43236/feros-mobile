import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supervisor_dashboard_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import 'supervisor_dashboard.dart';

/// Home tab body for the Supervisor shell.
class SupervisorHomeTab extends GetView<SupervisorDashboardController> {
  const SupervisorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.state.value == ViewState.loading) {
        return const ShimmerList(count: 4);
      }
      if (controller.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              Text('Something went wrong',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetchDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.fetchDashboard,
        color: const Color(0xFF1E3A5F),
        child: SupervisorDashboard(controller: controller),
      );
    });
  }
}
