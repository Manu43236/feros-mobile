import 'package:get/get.dart';

import '../middleware/auth_middleware.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

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

    // Login — no auth guard; Sprint 1 will add LoginView + LoginBinding
    GetPage(
      name: _Paths.LOGIN,
      page: () => const HomeView(), // placeholder until Sprint 1
      binding: HomeBinding(),
    ),

    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // All feature routes below share the AuthMiddleware.
    // Each will be replaced with their real View + Binding as sprints complete.
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
