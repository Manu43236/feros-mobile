import 'package:get/get.dart';
import '../controllers/service_men_breakdowns_controller.dart';

class ServiceMenBreakdownsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceMenBreakdownsController>(
      () => ServiceMenBreakdownsController(),
    );
  }
}
