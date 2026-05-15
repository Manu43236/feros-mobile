import 'package:get/get.dart';

class StoreKeeperInventoryController extends GetxController {
  final selectedTab = 0.obs;

  void goToPartsTab()    => selectedTab.value = 0;
  void goToRequestsTab() => selectedTab.value = 1;
}
