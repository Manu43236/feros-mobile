import 'package:get/get.dart';
import '../controllers/supervisor_payslip_controller.dart';

class SupervisorPayslipBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorPayslipController>(() => SupervisorPayslipController());
  }
}
