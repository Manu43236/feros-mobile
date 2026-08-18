import 'dart:convert';
import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class StorageService extends GetxService {
  static const _keyToken   = 'feros_token';
  static const _keyUser    = 'feros_user';
  static const _keyLocale  = 'feros_locale';
  static const _keyLockout = 'feros_lockout_until';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> saveUser(UserModel user) =>
      _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<String?> getRole() async {
    final user = await getUser();
    return user?.role;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveLocale(Locale locale) =>
      _storage.write(key: _keyLocale, value: '${locale.languageCode}_${locale.countryCode}');

  Future<Locale?> getLocale() async {
    final raw = await _storage.read(key: _keyLocale);
    if (raw == null) return null;
    final parts = raw.split('_');
    if (parts.length < 2) return null;
    return Locale(parts[0], parts[1]);
  }

  Future<void> saveLockout(DateTime until) =>
      _storage.write(key: _keyLockout, value: until.toIso8601String());

  Future<DateTime?> getLockout() async {
    final raw = await _storage.read(key: _keyLockout);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearLockout() => _storage.delete(key: _keyLockout);

  Future<void> clearAll() => _storage.deleteAll();
}
