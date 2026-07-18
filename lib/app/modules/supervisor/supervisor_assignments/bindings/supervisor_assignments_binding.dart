import 'package:get/get.dart';
import '../controllers/supervisor_assignments_controller.dart';

class SupervisorAssignmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorAssignmentsController>(
      () => SupervisorAssignmentsController(),
    );
  }
}
