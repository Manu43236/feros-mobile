import 'package:get/get.dart';
import '../controllers/supervisor_shell_controller.dart';
import '../../supervisor_dashboard/controllers/supervisor_dashboard_controller.dart';

class SupervisorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorShellController>(() => SupervisorShellController());
    Get.lazyPut<SupervisorDashboardController>(() => SupervisorDashboardController());
  }
}
