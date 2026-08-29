import 'dart:ui';
import 'package:feros/core/services/storage_service.dart';
import 'package:feros/core/models/user_model.dart';

class FakeStorageService extends StorageService {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override Future<UserModel?> getUser() async => null;
  @override Future<bool> isLoggedIn() async => true;
  @override Future<String?> getRole() async => null;
  @override Future<String?> getToken() async => null;
  @override Future<void> saveToken(String t) async {}
  @override Future<void> saveUser(UserModel u) async {}
  @override Future<void> clearAll() async {}
  @override Future<void> saveLocale(Locale locale) async {}
  @override Future<Locale?> getLocale() async => null;
  @override Future<void> saveLockout(DateTime until) async {}
  @override Future<DateTime?> getLockout() async => null;
  @override Future<void> clearLockout() async {}
}
