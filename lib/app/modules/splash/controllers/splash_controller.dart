import 'package:get/get.dart';
import '../../../../core/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final storage = Get.find<StorageService>();
      final isLoggedIn = await storage.isLoggedIn();

      if (isLoggedIn) {
        final role = await storage.getRole();
        Get.offAllNamed(_roleHome(role));
      } else {
        Get.offAllNamed(Routes.LOGIN);
      }
    } catch (_) {
      // Any storage error → send to login
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  String _roleHome(String? role) {
    switch (role) {
      case 'ADMIN':        return Routes.DASHBOARD;
      case 'OFFICE_STAFF': return Routes.ORDERS;
      case 'SUPERVISOR':   return Routes.ORDERS;
      case 'DRIVER':
      case 'CLEANER':      return Routes.MY_TRIPS;
      case 'SERVICE_MEN':  return Routes.VEHICLE_SERVICES;
      case 'STORE_KEEPER': return Routes.INVENTORY;
      default:             return Routes.LOGIN;
    }
  }
}
