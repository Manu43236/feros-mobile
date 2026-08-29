import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';

class SupervisorEquipmentShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  late final bool canAccessEquipment;
  late final bool canAccessLeases;

  // Both enabled → 4 tabs: Home / Work Orders / Leases / Attendance
  // Equipment only → 4 tabs: Home / Work Orders / Attendance / More
  // Leases only   → 4 tabs: Home / Leases / Attendance / More
  bool get bothEnabled => canAccessEquipment && canAccessLeases;

  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthService>().user;
    canAccessEquipment = user?.canAccessEquipment ?? false;
    canAccessLeases    = user?.canAccessLeases    ?? false;
  }

  void onTabTapped(int index) => currentIndex.value = index;

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
