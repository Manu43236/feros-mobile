import 'package:feros/app/modules/driver/driver_shell/bindings/driver_shell_binding.dart';
import 'package:feros/app/modules/driver/driver_shell/views/driver_shell_view.dart';
import 'package:get/get.dart';

import '../middleware/auth_middleware.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/supervisor/supervisor_shell/bindings/supervisor_shell_binding.dart';
import '../modules/supervisor/supervisor_shell/views/supervisor_shell_view.dart';
import '../modules/supervisor/supervisor_equipment_shell/bindings/supervisor_equipment_shell_binding.dart';
import '../modules/supervisor/supervisor_equipment_shell/views/supervisor_equipment_shell_view.dart';
import '../modules/driver/driver_notifications/views/driver_notifications_view.dart';
import '../modules/driver/driver_notifications/bindings/driver_notifications_binding.dart';
import '../modules/office/office_shell/views/office_shell_view.dart';
import '../modules/office/office_shell/bindings/office_shell_binding.dart';
import '../modules/login/views/force_pin_change_view.dart';
import '../modules/operator/operator_shell/bindings/operator_shell_binding.dart';
import '../modules/operator/operator_shell/views/operator_shell_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.SHELL,
      page: () => const DriverShellView(),
      binding: DriverShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.SUPERVISOR_SHELL,
      page: () => const SupervisorShellView(),
      binding: SupervisorShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.SUPERVISOR_EQUIPMENT_SHELL,
      page: () => const SupervisorEquipmentShellView(),
      binding: SupervisorEquipmentShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const DriverNotificationsView(),
      binding: DriverNotificationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.OFFICE_SHELL,
      page: () => const OfficeShellView(),
      binding: OfficeShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.OPERATOR_SHELL,
      page: () => const OperatorShellView(),
      binding: OperatorShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.FORCE_PIN_CHANGE,
      page: () => const ForcePinChangeView(),
    ),
  ];
}
