import 'package:get/get.dart';
import '../controllers/supervisor_vehicles_controller.dart';

class SupervisorVehiclesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorVehiclesController>(
      () => SupervisorVehiclesController(),
    );
  }
}
