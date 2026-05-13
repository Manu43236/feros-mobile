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
      case 'SUPERVISOR': return Routes.SUPERVISOR_SHELL;
      default: return Routes.SHELL;
    }
  }
}
