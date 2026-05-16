import 'package:get/get.dart';
import '../controllers/service_men_services_controller.dart';

class ServiceMenServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenServicesController>(
        () => ServiceMenServicesController());
  }
}
