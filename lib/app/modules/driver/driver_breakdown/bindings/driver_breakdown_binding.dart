import 'package:get/get.dart';
import '../controllers/driver_breakdown_controller.dart';

class DriverBreakdownBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverBreakdownController>(() => DriverBreakdownController());
  }
}
