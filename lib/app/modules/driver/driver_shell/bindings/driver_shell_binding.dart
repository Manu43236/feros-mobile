import 'package:feros/app/modules/driver/driver_shell/controllers/driver_shell_controller.dart';
import 'package:get/get.dart';

class DriverShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverShellController>(() => DriverShellController());
  }
}
