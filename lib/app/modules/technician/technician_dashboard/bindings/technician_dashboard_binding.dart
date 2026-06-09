import 'package:get/get.dart';
import '../controllers/technician_dashboard_controller.dart';

class TechnicianDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TechnicianDashboardController>(() => TechnicianDashboardController());
  }
}
