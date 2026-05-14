import 'package:get/get.dart';
import '../controllers/driver_shell_controller.dart';
import '../../driver_dashboard/bindings/driver_dashboard_binding.dart';
import '../../driver_trips/bindings/driver_trips_binding.dart';
import '../../driver_attendance/bindings/driver_attendance_binding.dart';
import '../../driver_profile/bindings/driver_profile_binding.dart';

class DriverShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverShellController>(() => DriverShellController());
    DriverDashboardBinding().dependencies();
    DriverTripsBinding().dependencies();
    DriverAttendanceBinding().dependencies();
    DriverProfileBinding().dependencies();
  }
}
