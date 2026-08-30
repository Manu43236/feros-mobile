import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../supervisor_dashboard/controllers/supervisor_dashboard_controller.dart';
import '../../supervisor_vehicles/controllers/supervisor_vehicles_controller.dart';
import '../../supervisor_crew/controllers/supervisor_crew_controller.dart';
import '../../supervisor_orders/controllers/supervisor_orders_controller.dart';

class SupervisorShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  void onTabTapped(int index) {
    currentIndex.value = index;
    if (index == 0) {
      Get.find<SupervisorDashboardController>().fetchDashboard();
    } else if (index == 1) {
      // Wishlist — refresh vehicles + crew
      final vc = Get.find<SupervisorVehiclesController>();
      final cc = Get.find<SupervisorCrewController>();
      vc.fetchVehicles();
      cc.fetchCrew();
    } else if (index == 2) {
      // Orders — refresh list
      Get.find<SupervisorOrdersController>().fetchOrders(reset: true);
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
