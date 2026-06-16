import 'package:get/get.dart';
import '../controllers/office_notifications_controller.dart';

class OfficeNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OfficeNotificationsController>(
        () => OfficeNotificationsController());
  }
}
