import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../office_dashboard/controllers/office_dashboard_controller.dart';
import '../../office_orders/controllers/office_orders_controller.dart';
import '../../../supervisor/supervisor_vehicles/controllers/supervisor_vehicles_controller.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class OfficeShellController extends GetxController {
  final _api = Get.find<ApiClient>();

  final currentIndex = 0.obs;
  final unreadCount  = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  @override
  void onReady() {
    super.onReady();
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      final res  = await _api.get(ApiEndpoints.notifUnreadCount);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
      unreadCount.value = (data['count'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void clearUnreadCount() => unreadCount.value = 0;

  void onTabTapped(int index) {
    currentIndex.value = index;
    switch (index) {
      case 0:
        Get.find<OfficeDashboardController>().fetchDashboard();
        break;
      case 1:
        Get.find<OfficeOrdersController>().fetchOrders(reset: true);
        break;
      case 2:
        Get.find<SupervisorVehiclesController>().fetchVehicles();
        break;
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
