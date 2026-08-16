import 'package:get/get.dart';
import '../controllers/supervisor_fuel_log_controller.dart';

class SupervisorFuelLogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorFuelLogController>(() => SupervisorFuelLogController(), fenix: true);
  }
}
