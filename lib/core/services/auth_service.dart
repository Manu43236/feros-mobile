import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../core/utils/env_config.dart';
import '../api/api_endpoints.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import '../../app/routes/app_pages.dart';

class AuthService extends GetxService {
  final _storage = Get.find<StorageService>();

  final currentUser = Rxn<UserModel>();

  @override
  void onInit() async {
    super.onInit();
    currentUser.value = await _storage.getUser();
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<String?> getRole() => _storage.getRole();

  UserModel? get user => currentUser.value;

  String get roleHome {
    switch (currentUser.value?.role) {
      case 'SUPERVISOR':
        // Rental supervisor (no vehicles) → rental shell
        // Vehicle supervisor (has vehicles) → existing shell (untouched)
        if (currentUser.value?.isRentalSupervisor == true) {
          return Routes.SUPERVISOR_EQUIPMENT_SHELL;
        }
        return Routes.SUPERVISOR_SHELL;
      case 'OFFICE_STAFF':
      case 'ADMIN':
        return Routes.OFFICE_SHELL;
      case 'OPERATOR':
        return Routes.OPERATOR_SHELL;
      default:
        return Routes.SHELL;
    }
  }

  Future<void> saveSession(String token, UserModel user) async {
    await _storage.saveToken(token);
    await _storage.saveUser(user);
    currentUser.value = user;
  }

  Future<void> logout() async {
    // Notify server to invalidate session (best-effort — don't block logout if it fails)
    try {
      await Get.find<ApiClient>().post(ApiEndpoints.logout);
    } catch (_) {}

    // Delete FCM token so this device stops receiving notifications immediately
    if (EnvConfig.isProd) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }

    Get.offAllNamed(Routes.LOGIN);
    await _storage.clearAll();
    currentUser.value = null;
  }
}
