import 'package:get/get.dart';
import '../controllers/driver_attendance_controller.dart';

class DriverAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverAttendanceController>(() => DriverAttendanceController());
  }
}
