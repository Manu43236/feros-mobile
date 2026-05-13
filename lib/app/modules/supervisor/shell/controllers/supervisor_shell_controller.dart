import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupervisorShellController extends GetxController {
  final currentIndex = 0.obs;
  final scaffoldKey  = GlobalKey<ScaffoldState>();

  void onTabTapped(int index) => currentIndex.value = index;
  void openDrawer()  => scaffoldKey.currentState?.openDrawer();
  void closeDrawer() => scaffoldKey.currentState?.closeDrawer();
}
