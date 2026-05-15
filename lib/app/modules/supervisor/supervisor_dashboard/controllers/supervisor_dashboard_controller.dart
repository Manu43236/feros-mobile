import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  // Orders
  final orderTotal     = 0.obs;
  final orderPending   = 0.obs;
  final orderActive    = 0.obs;
  final orderCompleted = 0.obs;
  final orderDelivered = 0.obs;
  final orderCancelled = 0.obs;

  // Vehicles
  final vehicleTotal     = 0.obs;
  final vehicleAvailable = 0.obs;
  final vehicleOnTrip    = 0.obs;
  final vehicleBreakdown = 0.obs;
  final vehicleInactive  = 0.obs;

  // Drivers
  final driverTotal     = 0.obs;
  final driverAvailable = 0.obs;
  final driverOnTrip    = 0.obs;
  final driverPresent   = 0.obs;

  // Cleaners
  final cleanerTotal     = 0.obs;
  final cleanerAvailable = 0.obs;
  final cleanerOnTrip    = 0.obs;
  final cleanerPresent   = 0.obs;

  // LRs
  final lrTotal     = 0.obs;
  final lrCreated   = 0.obs;
  final lrLoaded    = 0.obs;
  final lrInTransit = 0.obs;
  final lrDelivered = 0.obs;
  final lrCancelled = 0.obs;

  // Attendance
  final attTotal     = 0.obs;
  final attPresent   = 0.obs;
  final attAbsent    = 0.obs;
  final attHalfDay   = 0.obs;
  final attWeeklyOff = 0.obs;

  final unreadNotifications = 0.obs;

  // Self attendance
  final selfAttendance  = Rxn<Map<String, dynamic>>();   // null = not marked
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  final isSelfMarking   = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.dashboard),
        _api.get(ApiEndpoints.attendanceTypes),
      ]);

      final data = (results[0].data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      final o = (data['orders']     as Map<String, dynamic>?) ?? {};
      final v = (data['vehicles']   as Map<String, dynamic>?) ?? {};
      final d = (data['drivers']    as Map<String, dynamic>?) ?? {};
      final c = (data['cleaners']   as Map<String, dynamic>?) ?? {};
      final l = (data['lrs']        as Map<String, dynamic>?) ?? {};
      final a = (data['attendance'] as Map<String, dynamic>?) ?? {};

      orderTotal.value     = o['total']     as int? ?? 0;
      orderPending.value   = o['pending']   as int? ?? 0;
      orderActive.value    = o['active']    as int? ?? 0;
      orderCompleted.value = o['completed'] as int? ?? 0;
      orderDelivered.value = o['delivered'] as int? ?? 0;
      orderCancelled.value = o['cancelled'] as int? ?? 0;

      vehicleTotal.value     = v['total']     as int? ?? 0;
      vehicleAvailable.value = v['available'] as int? ?? 0;
      vehicleOnTrip.value    = v['onTrip']    as int? ?? 0;
      vehicleBreakdown.value = v['breakdown'] as int? ?? 0;
      vehicleInactive.value  = v['inactive']  as int? ?? 0;

      driverTotal.value     = d['total']        as int? ?? 0;
      driverAvailable.value = d['available']    as int? ?? 0;
      driverOnTrip.value    = d['onTrip']       as int? ?? 0;
      driverPresent.value   = d['todayPresent'] as int? ?? 0;

      cleanerTotal.value     = c['total']        as int? ?? 0;
      cleanerAvailable.value = c['available']    as int? ?? 0;
      cleanerOnTrip.value    = c['onTrip']       as int? ?? 0;
      cleanerPresent.value   = c['todayPresent'] as int? ?? 0;

      lrTotal.value     = l['total']     as int? ?? 0;
      lrCreated.value   = l['created']   as int? ?? 0;
      lrLoaded.value    = l['loaded']    as int? ?? 0;
      lrInTransit.value = l['inTransit'] as int? ?? 0;
      lrDelivered.value = l['delivered'] as int? ?? 0;
      lrCancelled.value = l['cancelled'] as int? ?? 0;

      attTotal.value     = a['total']     as int? ?? 0;
      attPresent.value   = a['present']   as int? ?? 0;
      attAbsent.value    = a['absent']    as int? ?? 0;
      attHalfDay.value   = a['halfDay']   as int? ?? 0;
      attWeeklyOff.value = a['weeklyOff'] as int? ?? 0;

      unreadNotifications.value = data['unreadNotifications'] as int? ?? 0;

      // Attendance types
      final typesData = (results[1].data as Map<String, dynamic>)['data'] as List?;
      if (typesData != null) {
        attendanceTypes.assignAll(
          typesData.cast<Map<String, dynamic>>()
              .where((t) => t['isActive'] as bool? ?? true)
              .toList(),
        );
      }

      // Self attendance today
      try {
        final todayRes = await _api.get(ApiEndpoints.attendanceTodayStatus);
        final todayData = (todayRes.data as Map<String, dynamic>)['data'];
        selfAttendance.value = todayData as Map<String, dynamic>?;
      } catch (_) {
        selfAttendance.value = null;
      }

      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Dashboard] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> markSelf(int typeId) async {
    isSelfMarking.value = true;
    try {
      final res = await _api.post(ApiEndpoints.myAttendance,
          data: {'attendanceTypeId': typeId});
      selfAttendance.value =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      FerosSnackbar.success('Attendance marked');
    } catch (e) {
      FerosSnackbar.error('Failed to mark attendance');
    }
    isSelfMarking.value = false;
  }
}
