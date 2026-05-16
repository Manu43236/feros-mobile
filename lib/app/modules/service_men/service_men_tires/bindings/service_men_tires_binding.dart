import 'package:get/get.dart';
import '../controllers/service_men_tires_controller.dart';

class ServiceMenTiresBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenTiresController>(() => ServiceMenTiresController());
  }
}
