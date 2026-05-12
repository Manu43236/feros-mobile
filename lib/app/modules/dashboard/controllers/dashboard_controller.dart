import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/view_state.dart';

class DashboardController extends GetxController {
  final _api = Get.find<ApiClient>();
  final auth = Get.find<AuthService>();

  final state = ViewState.initial.obs;

  // Dashboard stats
  final totalTrips = 0.obs;
  final pendingTrips = 0.obs;
  final isAttendanceMarked = false.obs;
  final unreadNotifications = 0.obs;

  // Upcoming trips (driver) — full list
  final upcomingTrips = <Map<String, dynamic>>[].obs;
  final upcomingTrip = Rxn<Map<String, dynamic>>();

  @override
  void onReady() {
    super.onReady();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final role = auth.user?.role ?? '';
      final isFieldRole = role == 'DRIVER' || role == 'CLEANER' ||
          role == 'SUPERVISOR' || role == 'SERVICE_MEN' || role == 'STORE_KEEPER';
      final endpoint = isFieldRole ? ApiEndpoints.myDashboard : ApiEndpoints.dashboard;

      final res = await _api.get(endpoint);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      totalTrips.value          = data['totalTrips']          as int? ?? 0;
      pendingTrips.value        = data['pendingTrips']         as int? ?? 0;
      isAttendanceMarked.value  = data['attendanceMarked']     as bool? ?? false;
      unreadNotifications.value = data['unreadNotifications']  as int? ?? 0;

      final trips = (data['upcomingTrips'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      upcomingTrips.value = trips;
      upcomingTrip.value = trips.isNotEmpty ? trips.first : null;

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get userName => auth.user?.name ?? '';
  String get userRole => auth.user?.role ?? '';
  String get roleLabel {
    switch (userRole) {
      case 'DRIVER':       return 'Driver';
      case 'CLEANER':      return 'Cleaner';
      case 'SUPERVISOR':   return 'Supervisor';
      case 'OFFICE_STAFF': return 'Office Staff';
      case 'SERVICE_MEN':  return 'Service Men';
      case 'STORE_KEEPER': return 'Store Keeper';
      case 'ADMIN':        return 'Admin';
      default:             return userRole;
    }
  }
}
