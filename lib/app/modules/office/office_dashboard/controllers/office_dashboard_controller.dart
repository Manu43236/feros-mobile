import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  // Orders
  final orderTotal              = 0.obs;
  final orderPending            = 0.obs;
  final orderPartiallyAssigned  = 0.obs;
  final orderFullyAssigned      = 0.obs;
  final orderInTransit          = 0.obs;
  final orderPartiallyDelivered = 0.obs;
  final orderDelivered          = 0.obs;
  final orderCancelled          = 0.obs;

  // Vehicles
  final vehicleTotal     = 0.obs;
  final vehicleOnTrip    = 0.obs;
  final vehicleAvailable = 0.obs;

  // Invoices
  final invoiceDraft          = 0.obs;
  final invoiceSent           = 0.obs;
  final invoicePartiallyPaid  = 0.obs;
  final invoiceOverdue        = 0.obs;
  final invoicePaid           = 0.obs;
  final invoiceOutstanding    = 0.0.obs;

  // Attendance today
  final attPresent  = 0.obs;
  final attAbsent   = 0.obs;
  final attHalfDay  = 0.obs;
  final attOnLeave  = 0.obs;
  final attTotal    = 0.obs;

  // Expiry alerts
  final vehicleAlerts = <Map<String, dynamic>>[].obs;
  final staffAlerts   = <Map<String, dynamic>>[].obs;
  final totalAlerts   = 0.obs;

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
        _api.get('${ApiEndpoints.expiryAlerts}?days=30'),
      ]);

      // ── Dashboard summary ─────────────────────────────────────────
      final data = (results[0].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

      final o = (data['orders']          as Map<String, dynamic>?) ?? {};
      final v = (data['vehicles']        as Map<String, dynamic>?) ?? {};
      final inv = (data['invoices']      as Map<String, dynamic>?) ?? {};
      final a = (data['todayAttendance'] as Map<String, dynamic>?) ?? {};

      orderTotal.value              = (o['total']              as num?)?.toInt() ?? 0;
      orderPending.value            = (o['pending']            as num?)?.toInt() ?? 0;
      orderPartiallyAssigned.value  = (o['partiallyAssigned']  as num?)?.toInt() ?? 0;
      orderFullyAssigned.value      = (o['fullyAssigned']      as num?)?.toInt() ?? 0;
      orderInTransit.value          = (o['inTransit']          as num?)?.toInt() ?? 0;
      orderPartiallyDelivered.value = (o['partiallyDelivered'] as num?)?.toInt() ?? 0;
      orderDelivered.value          = (o['delivered']          as num?)?.toInt() ?? 0;
      orderCancelled.value          = (o['cancelled']          as num?)?.toInt() ?? 0;

      vehicleTotal.value     = (v['total']     as num?)?.toInt() ?? 0;
      vehicleOnTrip.value    = (v['onTrip']    as num?)?.toInt() ?? 0;
      vehicleAvailable.value = (v['available'] as num?)?.toInt() ?? 0;

      invoiceDraft.value         = (inv['draft']           as num?)?.toInt() ?? 0;
      invoiceSent.value          = (inv['sent']            as num?)?.toInt() ?? 0;
      invoicePartiallyPaid.value = (inv['partiallyPaid']   as num?)?.toInt() ?? 0;
      invoiceOverdue.value       = (inv['overdue']         as num?)?.toInt() ?? 0;
      invoicePaid.value          = (inv['paid']            as num?)?.toInt() ?? 0;
      invoiceOutstanding.value   = (inv['totalOutstanding'] as num?)?.toDouble() ?? 0.0;

      attPresent.value  = (a['present']  as num?)?.toInt() ?? 0;
      attAbsent.value   = (a['absent']   as num?)?.toInt() ?? 0;
      attHalfDay.value  = (a['halfDay']  as num?)?.toInt() ?? 0;
      attOnLeave.value  = (a['onLeave']  as num?)?.toInt() ?? 0;
      attTotal.value    = (a['total']    as num?)?.toInt() ?? 0;

      // ── Expiry alerts ─────────────────────────────────────────────
      final alertData = (results[1].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

      final vAlerts = alertData['vehicleAlerts'] as List? ?? [];
      final sAlerts = alertData['staffDocumentAlerts'] as List? ?? [];

      vehicleAlerts.assignAll(vAlerts.cast<Map<String, dynamic>>());
      staffAlerts.assignAll(sAlerts.cast<Map<String, dynamic>>());
      totalAlerts.value = (alertData['totalAlerts'] as num?)?.toInt() ?? 0;

      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeDashboard] $e');
      state.value = ViewState.error;
    }
  }
}
