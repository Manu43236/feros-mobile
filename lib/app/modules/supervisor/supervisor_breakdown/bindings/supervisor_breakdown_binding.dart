import 'package:get/get.dart';
import '../controllers/supervisor_breakdown_controller.dart';

class SupervisorBreakdownBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorBreakdownController>(() => SupervisorBreakdownController());
  }
}
