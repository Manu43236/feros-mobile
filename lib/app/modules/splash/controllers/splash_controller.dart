import 'package:get/get.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final auth = Get.find<AuthService>();
    if (await auth.isLoggedIn()) {
      Get.offAllNamed(auth.roleHome);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
