import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class VehicleAlert {
  final int vehicleId;
  final String registrationNumber;
  final String alertType;
  final String? documentName;
  final String expiryDate;
  final int daysLeft;
  final bool expired;

  const VehicleAlert({
    required this.vehicleId,
    required this.registrationNumber,
    required this.alertType,
    this.documentName,
    required this.expiryDate,
    required this.daysLeft,
    required this.expired,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> j) => VehicleAlert(
        vehicleId: j['vehicleId'] as int,
        registrationNumber: j['registrationNumber'] as String,
        alertType: j['alertType'] as String,
        documentName: j['documentName'] as String?,
        expiryDate: j['expiryDate'] as String,
        daysLeft: j['daysLeft'] as int,
        expired: j['expired'] as bool,
      );
}

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

  // Vehicle document alerts
  final alerts = <VehicleAlert>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      final res  = await _api.get('${ApiEndpoints.expiryAlerts}?days=30');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final list = (data['vehicleAlerts'] as List<dynamic>? ?? []);
      alerts.value = list
          .map((e) => VehicleAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Dashboard:alerts] $e');
    }
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.dashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

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

      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Dashboard] $e');
      state.value = ViewState.error;
    }
  }

}
