import 'package:get/get.dart';
import '../controllers/driver_trip_detail_controller.dart';

class DriverTripDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverTripDetailController>(() => DriverTripDetailController());
  }
}
