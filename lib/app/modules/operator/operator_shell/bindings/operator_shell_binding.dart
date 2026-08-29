import 'package:get/get.dart';
import '../controllers/operator_shell_controller.dart';
import '../../operator_dashboard/controllers/operator_dashboard_controller.dart';
import '../../../driver/driver_profile/bindings/driver_profile_binding.dart';
import '../../../driver/driver_attendance/bindings/driver_attendance_binding.dart';
import '../../../supervisor/supervisor_payslip/bindings/supervisor_payslip_binding.dart';

class OperatorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorShellController>(() => OperatorShellController());
    Get.lazyPut<OperatorDashboardController>(() => OperatorDashboardController());
    DriverProfileBinding().dependencies();
    DriverAttendanceBinding().dependencies();
    SupervisorPayslipBinding().dependencies();
  }
}
