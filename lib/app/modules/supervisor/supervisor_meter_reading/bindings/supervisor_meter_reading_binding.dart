import 'package:get/get.dart';
import '../controllers/supervisor_meter_reading_controller.dart';

class SupervisorMeterReadingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorMeterReadingController>(
      () => SupervisorMeterReadingController(),
    );
  }
}
