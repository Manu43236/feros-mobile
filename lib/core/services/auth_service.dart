import 'package:get/get.dart';
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
        return Routes.SUPERVISOR_SHELL;
      case 'OFFICE_STAFF':
      case 'ADMIN':
        return Routes.OFFICE_SHELL;
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
    Get.offAllNamed(Routes.LOGIN);
    await _storage.clearAll();
    currentUser.value = null;
  }
}
