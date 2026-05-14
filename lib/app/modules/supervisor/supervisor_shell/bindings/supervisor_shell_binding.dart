import 'package:get/get.dart';
import '../controllers/supervisor_shell_controller.dart';
import '../../supervisor_dashboard/controllers/supervisor_dashboard_controller.dart';
import '../../supervisor_orders/controllers/supervisor_orders_controller.dart';
import '../../supervisor_active_trips/controllers/supervisor_active_trips_controller.dart';
import '../../supervisor_attendance/controllers/supervisor_attendance_controller.dart';

class SupervisorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorShellController>(() => SupervisorShellController());
    Get.lazyPut<SupervisorDashboardController>(() => SupervisorDashboardController());
    Get.lazyPut<SupervisorOrdersController>(() => SupervisorOrdersController());
    Get.lazyPut<SupervisorActiveTripsController>(() => SupervisorActiveTripsController());
    Get.lazyPut<SupervisorAttendanceController>(() => SupervisorAttendanceController());
  }
}
