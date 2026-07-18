import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorAssignmentsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final historyState = ViewState.loading.obs;
  final orders       = <Map<String, dynamic>>[].obs;
  final vehicleHistory = <Map<String, dynamic>>[].obs;
  final staffHistory   = <Map<String, dynamic>>[].obs;
  final searchQuery  = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.orders, params: {'size': 1000});
      final page = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final list = (page['content'] as List).cast<Map<String, dynamic>>();
      orders.assignAll(list.where((o) {
        final st = o['orderStatus'] as String? ?? '';
        return !['CANCELLED', 'COMPLETED'].contains(st);
      }).toList());
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Assignments] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> fetchHistory() async {
    if (vehicleHistory.isNotEmpty) return;
    historyState.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.vehicleAllocationHistory),
        _api.get(ApiEndpoints.staffAssignmentHistory),
      ]);
      vehicleHistory.assignAll(
        ((results[0].data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      staffHistory.assignAll(
        ((results[1].data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      historyState.value = ViewState.success;
    } catch (e) {
      debugPrint('[Assignments History] $e');
      historyState.value = ViewState.error;
    }
  }

  List<Map<String, dynamic>> get vehicleRows {
    final rows = <Map<String, dynamic>>[];
    for (final o in orders) {
      final allocs = (o['vehicleAllocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final va in allocs) {
        if ((va['allocationStatus'] as String? ?? '') == 'CANCELLED') continue;
        final staffAllocs = (va['staffAllocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        rows.add({
          'orderNumber': o['orderNumber'] as String? ?? '',
          'clientName':  o['clientName']  as String? ?? '',
          'vehicle':     va['vehicleRegistrationNumber'] as String? ?? '—',
          'weight':      va['allocatedWeight'],
          'status':      va['allocationStatus'] as String? ?? '',
          'loadDate':    va['expectedLoadDate'],
          'driverCount': staffAllocs.where((sa) => sa['roleName'] == 'DRIVER').length,
          'assignedBy':  va['allocatedByName'],
        });
      }
    }
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) =>
      (r['orderNumber'] as String).toLowerCase().contains(q) ||
      (r['vehicle']     as String).toLowerCase().contains(q) ||
      (r['clientName']  as String).toLowerCase().contains(q)
    ).toList();
  }

  List<Map<String, dynamic>> get driverRows {
    final rows = <Map<String, dynamic>>[];
    for (final o in orders) {
      final allocs = (o['vehicleAllocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final va in allocs) {
        final staffAllocs = (va['staffAllocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final sa in staffAllocs) {
          if ((sa['allocationStatus'] as String? ?? '') == 'CANCELLED') continue;
          rows.add({
            'orderNumber': o['orderNumber'] as String? ?? '',
            'vehicle':     va['vehicleRegistrationNumber'] as String? ?? '—',
            'staffName':   sa['userName']  as String? ?? '—',
            'roleName':    sa['roleName']  as String? ?? '',
            'status':      sa['allocationStatus'] as String? ?? '',
            'startDate':   sa['expectedStartDate'],
            'assignedBy':  sa['allocatedByName'],
          });
        }
      }
    }
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) =>
      (r['orderNumber'] as String).toLowerCase().contains(q) ||
      (r['vehicle']     as String).toLowerCase().contains(q) ||
      (r['staffName']   as String).toLowerCase().contains(q)
    ).toList();
  }
}
