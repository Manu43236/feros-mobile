import 'package:get/get.dart';
import '../controllers/supervisor_notifications_controller.dart';

class SupervisorNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorNotificationsController>(
        () => SupervisorNotificationsController());
  }
}
