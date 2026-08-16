import 'package:get/get.dart';
import '../controllers/office_shell_controller.dart';
import '../../office_dashboard/controllers/office_dashboard_controller.dart';
import '../../office_orders/controllers/office_orders_controller.dart';
import '../../../supervisor/supervisor_vehicles/controllers/supervisor_vehicles_controller.dart';
import '../../../supervisor/supervisor_profile/controllers/supervisor_profile_controller.dart';

class OfficeShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OfficeShellController>(() => OfficeShellController());
    Get.lazyPut<OfficeDashboardController>(() => OfficeDashboardController());
    Get.lazyPut<OfficeOrdersController>(() => OfficeOrdersController());
    Get.lazyPut<SupervisorVehiclesController>(() => SupervisorVehiclesController());
    Get.lazyPut<SupervisorProfileController>(() => SupervisorProfileController());
  }
}
