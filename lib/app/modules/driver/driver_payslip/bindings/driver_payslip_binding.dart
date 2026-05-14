import 'package:get/get.dart';
import '../controllers/driver_payslip_controller.dart';

class DriverPayslipBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverPayslipController>(() => DriverPayslipController());
  }
}
