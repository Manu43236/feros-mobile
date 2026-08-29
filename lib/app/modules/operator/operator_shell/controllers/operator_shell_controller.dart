import 'package:get/get.dart';

class OperatorShellController extends GetxController {
  final currentIndex = 0.obs;

  void onTabTapped(int index) => currentIndex.value = index;
}
