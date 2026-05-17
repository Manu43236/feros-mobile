import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../office_dashboard/controllers/office_dashboard_controller.dart';

class OfficeShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  void onTabTapped(int index) {
    currentIndex.value = index;
    if (index == 0) {
      Get.find<OfficeDashboardController>().fetchDashboard();
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
