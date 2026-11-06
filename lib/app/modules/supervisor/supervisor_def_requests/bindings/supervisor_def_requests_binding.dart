import 'package:get/get.dart';
import '../controllers/supervisor_def_requests_controller.dart';

class SupervisorDefRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorDefRequestsController>(() => SupervisorDefRequestsController(), fenix: true);
  }
}
