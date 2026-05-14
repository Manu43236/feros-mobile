import 'package:get/get.dart';
import '../controllers/supervisor_crew_controller.dart';

class SupervisorCrewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorCrewController>(() => SupervisorCrewController());
  }
}
