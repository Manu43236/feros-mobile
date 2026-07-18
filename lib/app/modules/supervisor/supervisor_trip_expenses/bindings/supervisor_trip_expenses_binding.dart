import 'package:get/get.dart';
import '../controllers/supervisor_trip_expenses_controller.dart';

class SupervisorTripExpensesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorTripExpensesController>(
      () => SupervisorTripExpensesController(),
    );
  }
}
