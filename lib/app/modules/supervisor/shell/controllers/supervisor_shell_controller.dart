import 'package:get/get.dart';

class SupervisorShellController extends GetxController {
  final currentIndex = 0.obs;

  void onTabTapped(int index) => currentIndex.value = index;
}
