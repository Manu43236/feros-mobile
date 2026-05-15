import 'package:get/get.dart';
import '../controllers/store_keeper_profile_controller.dart';

class StoreKeeperProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreKeeperProfileController>(() => StoreKeeperProfileController());
  }
}
