import 'package:get/get.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';

class DriverDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
