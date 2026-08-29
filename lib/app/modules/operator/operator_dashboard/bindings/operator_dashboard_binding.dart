import 'package:get/get.dart';
import '../controllers/operator_dashboard_controller.dart';

class OperatorDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorDashboardController>(() => OperatorDashboardController());
  }
}
