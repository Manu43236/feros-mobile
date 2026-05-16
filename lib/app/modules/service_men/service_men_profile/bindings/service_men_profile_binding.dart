import 'package:get/get.dart';
import '../controllers/service_men_profile_controller.dart';

class ServiceMenProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenProfileController>(
        () => ServiceMenProfileController());
  }
}
