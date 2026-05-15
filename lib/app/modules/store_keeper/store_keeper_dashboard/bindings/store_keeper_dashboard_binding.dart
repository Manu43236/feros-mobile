import 'package:get/get.dart';
import '../controllers/store_keeper_dashboard_controller.dart';

class StoreKeeperDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreKeeperDashboardController>(() => StoreKeeperDashboardController());
  }
}
