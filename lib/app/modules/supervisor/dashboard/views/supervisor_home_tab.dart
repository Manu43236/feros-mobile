import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import 'supervisor_dashboard.dart';

/// Home tab body for the Supervisor shell.
/// Initialises its own DashboardController — fully isolated from the
/// Driver/Cleaner shell so the existing flow is never touched.
class SupervisorHomeTab extends StatelessWidget {
  const SupervisorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: DashboardController(),
      tag: 'supervisor',
      builder: (ctrl) => Obx(() {
        if (ctrl.state.value == ViewState.loading) {
          return const ShimmerList(count: 4);
        }
        return RefreshIndicator(
          onRefresh: ctrl.fetchDashboard,
          color: const Color(0xFF1E3A5F),
          child: SupervisorDashboard(controller: ctrl),
        );
      }),
    );
  }
}
