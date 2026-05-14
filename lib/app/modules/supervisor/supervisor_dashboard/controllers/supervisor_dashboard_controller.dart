import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  final totalTrips          = 0.obs;
  final pendingTrips        = 0.obs;
  final unreadNotifications = 0.obs;

  @override
  void onReady() {
    super.onReady();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.myDashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      totalTrips.value          = data['totalTrips']          as int? ?? 0;
      pendingTrips.value        = data['pendingTrips']         as int? ?? 0;
      unreadNotifications.value = data['unreadNotifications']  as int? ?? 0;

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
