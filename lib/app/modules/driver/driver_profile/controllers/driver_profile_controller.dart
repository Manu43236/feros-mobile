import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/popups/feros_dialog.dart';

class DriverProfileController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final totalTrips = Rxn<int>();

  AuthService get auth => _auth;

  bool get showTrips {
    final role = _auth.user?.role ?? '';
    return role == 'DRIVER' || role == 'CLEANER';
  }

  @override
  void onReady() {
    super.onReady();
    if (showTrips) _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final res  = await _api.get(ApiEndpoints.myDashboard);
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
