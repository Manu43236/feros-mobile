import 'package:get/get.dart';
import '../controllers/vehicle_leases_controller.dart';

class VehicleLeasesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleLeasesController>(() => VehicleLeasesController());
  }
}
