import 'package:get/get.dart';
import '../controllers/driver_trips_controller.dart';

class DriverTripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverTripsController>(() => DriverTripsController());
  }
}
