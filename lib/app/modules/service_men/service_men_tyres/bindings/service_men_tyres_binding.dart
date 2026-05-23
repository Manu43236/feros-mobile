import 'package:get/get.dart';
import '../controllers/service_men_tyres_controller.dart';

class ServiceMenTyresBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenTyresController>(() => ServiceMenTyresController());
  }
}
