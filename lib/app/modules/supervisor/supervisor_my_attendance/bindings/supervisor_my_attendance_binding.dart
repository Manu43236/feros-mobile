import 'package:get/get.dart';
import '../controllers/supervisor_my_attendance_controller.dart';

class SupervisorMyAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorMyAttendanceController>(
        () => SupervisorMyAttendanceController());
  }
}
