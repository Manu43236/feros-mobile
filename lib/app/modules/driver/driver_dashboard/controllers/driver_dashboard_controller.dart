import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/utils/view_state.dart';

class DriverDashboardController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final state = ViewState.initial.obs;

  final isAttendanceMarked   = false.obs;
  final isAttendanceEnforced = false.obs;
  final unreadNotifications  = 0.obs;

  final activeTrip    = Rxn<Map<String, dynamic>>();
  final upcomingTrips = <Map<String, dynamic>>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final role = _auth.user?.role ?? '';
      const fieldRoles = {'DRIVER', 'CLEANER', 'SERVICE_MEN', 'STORE_KEEPER'};
      final endpoint = fieldRoles.contains(role)
          ? ApiEndpoints.myDashboard
          : ApiEndpoints.dashboard;
      final res  = await _api.get(endpoint);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      isAttendanceMarked.value   = data['attendanceMarked']    as bool? ?? false;
      isAttendanceEnforced.value = data['attendanceEnforced']  as bool? ?? false;
      unreadNotifications.value  = data['unreadNotifications'] as int?  ?? 0;

      activeTrip.value = data['activeTrip'] as Map<String, dynamic>?;

      final trips = (data['upcomingTrips'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      upcomingTrips.value = trips;

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
