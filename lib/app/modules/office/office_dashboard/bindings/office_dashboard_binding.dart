import 'package:get/get.dart';
import '../controllers/office_dashboard_controller.dart';

class OfficeDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OfficeDashboardController>(() => OfficeDashboardController());
  }
}
