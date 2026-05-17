import 'package:get/get.dart';
import '../controllers/office_orders_controller.dart';

class OfficeOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OfficeOrdersController>(() => OfficeOrdersController());
  }
}
