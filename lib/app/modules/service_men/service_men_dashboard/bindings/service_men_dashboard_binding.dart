import 'package:get/get.dart';
import '../controllers/service_men_dashboard_controller.dart';

class ServiceMenDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenDashboardController>(
        () => ServiceMenDashboardController());
  }
}
