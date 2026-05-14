import 'package:get/get.dart';
import '../controllers/supervisor_profile_controller.dart';

class SupervisorProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorProfileController>(() => SupervisorProfileController());
  }
}
