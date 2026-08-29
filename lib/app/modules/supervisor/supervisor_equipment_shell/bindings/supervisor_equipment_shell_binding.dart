import 'package:get/get.dart';
import '../controllers/supervisor_equipment_shell_controller.dart';
import '../work_orders/controllers/equip_work_orders_controller.dart';
import '../attendance/controllers/equip_attendance_controller.dart';
import '../../../vehicle_leases/controllers/vehicle_leases_controller.dart';

class SupervisorEquipmentShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorEquipmentShellController>(
      () => SupervisorEquipmentShellController(),
    );
    Get.lazyPut<EquipWorkOrdersController>(
      () => EquipWorkOrdersController(),
    );
    Get.lazyPut<EquipAttendanceController>(
      () => EquipAttendanceController(),
    );
    Get.lazyPut<VehicleLeasesController>(
      () => VehicleLeasesController(),
    );
  }
}
