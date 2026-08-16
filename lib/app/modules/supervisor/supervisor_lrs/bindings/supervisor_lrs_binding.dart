import 'package:get/get.dart';
import '../controllers/supervisor_lrs_controller.dart';

class SupervisorLrsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorLrsController>(() => SupervisorLrsController(), fenix: true);
  }
}
