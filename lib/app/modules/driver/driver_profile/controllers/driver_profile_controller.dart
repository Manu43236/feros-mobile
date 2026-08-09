import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/popups/feros_dialog.dart';

class DriverProfileController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final totalTrips    = Rxn<int>();
  final myDocs        = <Map<String, dynamic>>[].obs;
  final isDocsLoading = false.obs;
  final appVersion    = 'FEROS'.obs;

  AuthService get auth => _auth;

  bool get showTrips {
    final role = _auth.user?.role ?? '';
    return role == 'DRIVER' || role == 'CLEANER';
  }

  @override
  void onReady() {
    super.onReady();
    if (showTrips) _fetchTrips();
    _fetchMyDocs();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = 'FEROS v${info.version}';
  }

  Future<void> _fetchMyDocs() async {
    isDocsLoading.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.driverMyDocs());
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      myDocs.value = List<Map<String, dynamic>>.from(data['myDocs'] as List? ?? []);
    } catch (_) {}
    isDocsLoading.value = false;
  }

  Future<void> _fetchTrips() async {
    try {
      final res  = await _api.get(ApiEndpoints.dashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      totalTrips.value = data['totalTrips'] as int? ?? 0;
    } catch (_) {}
  }

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
