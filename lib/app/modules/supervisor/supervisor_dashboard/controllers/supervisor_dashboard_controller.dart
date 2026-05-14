import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  final totalOrders         = 0.obs;
  final activeOrders        = 0.obs;
  final pendingAssignments  = 0.obs;
  final todayPresent        = 0.obs;
  final unreadNotifications = 0.obs;

  final activeTrips = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.dashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      totalOrders.value         = data['totalOrders']         as int? ?? 0;
      activeOrders.value        = data['activeOrders']        as int? ?? 0;
      pendingAssignments.value  = data['pendingAssignments']  as int? ?? 0;
      todayPresent.value        = data['todayPresent']        as int? ?? 0;
      unreadNotifications.value = data['unreadNotifications'] as int? ?? 0;

      activeTrips.value = (data['activeTrips'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
