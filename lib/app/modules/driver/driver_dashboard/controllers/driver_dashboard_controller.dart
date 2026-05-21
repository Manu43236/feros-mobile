import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class DriverDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  final isAttendanceMarked   = false.obs;
  final isAttendanceEnforced = false.obs;
  final unreadNotifications  = 0.obs;

  final activeTrip           = Rxn<Map<String, dynamic>>();
  final upcomingTrips        = <Map<String, dynamic>>[].obs;
  final hasActiveTripBreakdown = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.dashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      isAttendanceMarked.value   = data['attendanceMarked']    as bool? ?? false;
      isAttendanceEnforced.value = data['attendanceEnforced']  as bool? ?? false;
      unreadNotifications.value  = data['unreadNotifications'] as int?  ?? 0;

      final trip = data['activeTrip'] as Map<String, dynamic>?;
      activeTrip.value = trip;
      hasActiveTripBreakdown.value = trip?['hasActiveBreakdown'] as bool? ?? false;

      final trips = (data['upcomingTrips'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      upcomingTrips.value = trips;

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
