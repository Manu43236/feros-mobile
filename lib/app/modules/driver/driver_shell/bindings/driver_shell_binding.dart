import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../controllers/driver_shell_controller.dart';
import '../../driver_dashboard/bindings/driver_dashboard_binding.dart';
import '../../driver_trips/bindings/driver_trips_binding.dart';
import '../../driver_attendance/bindings/driver_attendance_binding.dart';
import '../../driver_profile/bindings/driver_profile_binding.dart';
import '../../../store_keeper/store_keeper_dashboard/bindings/store_keeper_dashboard_binding.dart';
import '../../../store_keeper/store_keeper_requests/bindings/store_keeper_requests_binding.dart';
import '../../../store_keeper/store_keeper_profile/bindings/store_keeper_profile_binding.dart';
import '../../../store_keeper/store_keeper_inventory/controllers/store_keeper_inventory_controller.dart';
import '../../../service_men/service_men_dashboard/bindings/service_men_dashboard_binding.dart';
import '../../../service_men/service_men_services/bindings/service_men_services_binding.dart';
import '../../../service_men/service_men_profile/bindings/service_men_profile_binding.dart';
import '../../../service_men/service_men_tyres/bindings/service_men_tyres_binding.dart';
import '../../../technician/technician_dashboard/bindings/technician_dashboard_binding.dart';

class DriverShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverShellController>(() => DriverShellController());

    final role = Get.find<AuthService>().user?.role ?? '';

    if (role == 'TECHNICIAN') {
      TechnicianDashboardBinding().dependencies();
      DriverAttendanceBinding().dependencies();
      DriverProfileBinding().dependencies();
    } else if (role == 'STORE_KEEPER') {
      Get.lazyPut<StoreKeeperInventoryController>(
          () => StoreKeeperInventoryController());
      StoreKeeperDashboardBinding().dependencies();
      StoreKeeperRequestsBinding().dependencies();
      DriverAttendanceBinding().dependencies();
      StoreKeeperProfileBinding().dependencies();
    } else if (role == 'SERVICE_MANAGER') {
      ServiceMenDashboardBinding().dependencies();
      ServiceMenServicesBinding().dependencies();
      ServiceMenTyresBinding().dependencies();
      DriverAttendanceBinding().dependencies();
      ServiceMenProfileBinding().dependencies();
    } else {
      DriverDashboardBinding().dependencies();
      DriverTripsBinding().dependencies();
      DriverAttendanceBinding().dependencies();
      DriverProfileBinding().dependencies();
    }
  }
}
