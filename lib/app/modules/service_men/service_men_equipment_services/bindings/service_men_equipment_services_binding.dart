import 'package:get/get.dart';
import '../controllers/service_men_equipment_services_controller.dart';

class ServiceMenEquipmentServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenEquipmentServicesController>(
      () => ServiceMenEquipmentServicesController(),
    );
  }
}
