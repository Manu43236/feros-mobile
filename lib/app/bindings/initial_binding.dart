import 'package:get/get.dart';
import '../../core/api/api_client.dart';
import '../../core/localization/locale_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/services/update_service.dart';

/// Registered once at app startup — always available throughout the app.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ApiClient>(ApiClient(), permanent: true);
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<UploadService>(UploadService(), permanent: true);
    Get.put<LocaleService>(LocaleService(), permanent: true);
    Get.put<UpdateService>(UpdateService(), permanent: true);
  }
}
