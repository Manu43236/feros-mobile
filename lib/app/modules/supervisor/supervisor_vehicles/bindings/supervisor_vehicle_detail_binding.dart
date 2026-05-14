import 'package:get/get.dart';
import '../controllers/supervisor_vehicle_detail_controller.dart';

class SupervisorVehicleDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorVehicleDetailController>(
      () => SupervisorVehicleDetailController(),
    );
  }
}
