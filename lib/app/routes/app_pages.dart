import 'package:feros/app/modules/driver/driver_shell/bindings/driver_shell_binding.dart';
import 'package:feros/app/modules/driver/driver_shell/views/driver_shell_view.dart';
import 'package:get/get.dart';

import '../middleware/auth_middleware.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/supervisor/shell/views/supervisor_shell_view.dart';
import '../modules/driver/driver_notifications/views/driver_notifications_view.dart';
import '../modules/driver/driver_notifications/bindings/driver_notifications_binding.dart';

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
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const DriverNotificationsView(),
      binding: DriverNotificationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
