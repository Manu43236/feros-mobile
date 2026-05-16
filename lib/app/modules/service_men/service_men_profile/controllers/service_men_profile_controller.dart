import 'package:get/get.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/popups/feros_dialog.dart';

class ServiceMenProfileController extends GetxController {
  final _auth = Get.find<AuthService>();
  AuthService get auth => _auth;

  Future<void> logout() async {
    final confirmed = await FerosDialog.confirm(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: true,
    );
    if (confirmed) _auth.logout();
  }
}
