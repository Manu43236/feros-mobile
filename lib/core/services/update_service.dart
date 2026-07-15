import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api/api_client.dart';

class UpdateService extends GetxService {
  @override
  void onInit() {
    super.onInit();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final config = await _fetchConfig();
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;

      final forceImmediate = config['forceUpdate'] == true ||
          currentVersion < (config['minVersion'] as int? ?? 0);

      if (forceImmediate && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // update check must never crash the app
    }
  }

  Future<Map<String, dynamic>> _fetchConfig() async {
    try {
      final api = Get.find<ApiClient>();
      final response = await api.get('/app/config');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {};
    }
  }
}
