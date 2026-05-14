import 'package:get/get.dart';
import '../controllers/driver_fuel_log_controller.dart';

class DriverFuelLogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverFuelLogController>(() => DriverFuelLogController());
  }
}
