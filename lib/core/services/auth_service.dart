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

  Future<void> saveSession(String token, UserModel user) async {
    await _storage.saveToken(token);
    await _storage.saveUser(user);
    currentUser.value = user;
  }

  Future<void> logout() async {
    await _storage.clearAll();
    currentUser.value = null;
    Get.offAllNamed(Routes.LOGIN);
  }
}
