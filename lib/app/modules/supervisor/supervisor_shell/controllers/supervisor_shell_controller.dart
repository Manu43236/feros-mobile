import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../supervisor_dashboard/controllers/supervisor_dashboard_controller.dart';

class SupervisorShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  void onTabTapped(int index) {
    currentIndex.value = index;
    if (index == 0) {
      Get.find<SupervisorDashboardController>().fetchDashboard();
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
