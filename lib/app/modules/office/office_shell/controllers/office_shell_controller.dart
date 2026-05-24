import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../office_dashboard/controllers/office_dashboard_controller.dart';
import '../../office_orders/controllers/office_orders_controller.dart';
import '../../../supervisor/supervisor_vehicles/controllers/supervisor_vehicles_controller.dart';

class OfficeShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

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
