import 'package:get/get.dart';
import '../controllers/store_keeper_requests_controller.dart';

class StoreKeeperRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreKeeperRequestsController>(() => StoreKeeperRequestsController());
  }
}
