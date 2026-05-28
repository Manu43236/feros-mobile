import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorVehiclesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state          = ViewState.loading.obs;
  final _allVehicles   = <Map<String, dynamic>>[].obs;
  final vehicles       = <Map<String, dynamic>>[].obs;
  final searchQuery    = ''.obs;
  final selectedStatus = 'ALL'.obs;

  // ── Staff assignment ──────────────────────────────────────────────────────
  final staffUsers      = <Map<String, dynamic>>[].obs;
  final isLoadingStaff  = false.obs;
  final savingVehicleId = Rxn<int>();
  bool _staffLoaded     = false;

  /// Distinct status names present in the fetched list
  List<String> get statusOptions {
    final set = <String>{};
    for (final v in _allVehicles) {
      final s = v['currentStatusName'] as String?;
      if (s != null && s.isNotEmpty) set.add(s);
    }
    return set.toList()..sort();
  }

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    state.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicles);
      final data = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      // LIFO
      _allVehicles.assignAll(data.reversed.toList());
      _apply();
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  void onSearch(String q) {
    searchQuery.value = q;
    _apply();
  }

  void onStatusFilter(String status) {
    selectedStatus.value = status;
    _apply();
  }

  void _apply() {
    var list = List<Map<String, dynamic>>.from(_allVehicles);

    // Status filter
    if (selectedStatus.value != 'ALL') {
      list = list
          .where((v) => v['currentStatusName'] == selectedStatus.value)
          .toList();
    }

    // Search
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((v) {
        final reg    = (v['registrationNumber'] as String? ?? '').toLowerCase();
        final type   = (v['vehicleTypeName']    as String? ?? '').toLowerCase();
        final brand  = (v['brandName']          as String? ?? '').toLowerCase();
        return reg.contains(q) || type.contains(q) || brand.contains(q);
      }).toList();
    }

    vehicles.assignAll(list);
  }

  // ── Load available staff (today's attendance, not yet assigned) ───────────
  Future<void> loadStaffUsers() async {
    if (_staffLoaded) return;
    _staffLoaded = true;
    isLoadingStaff.value = true;
    try {
      final res = await _api.get(
        ApiEndpoints.users,
        params: {'hasAttendanceToday': true},
      );
      final all = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      staffUsers.assignAll(all.where((u) {
        final role     = u['role']       as String? ?? '';
        final active   = u['isActive']   as bool?   ?? false;
        final assigned = u['isAssigned'] as bool?   ?? false;
        return active && !assigned && (role == 'DRIVER' || role == 'CLEANER');
      }).toList());
    } catch (e) {
      debugPrint('[Vehicles] load staff error: $e');
    }
    isLoadingStaff.value = false;
  }

  Future<bool> assignDriver(int vehicleId, int userId) async {
    savingVehicleId.value = vehicleId;
    try {
      await _api.put(ApiEndpoints.vehicleAssignDriver(vehicleId), data: {'userId': userId});
      _staffLoaded = false; // allow reload so newly assigned person is removed from list
      await fetchVehicles();
      return true;
    } catch (e) {
      debugPrint('[Vehicles] assign driver error: $e');
      return false;
    } finally {
      savingVehicleId.value = null;
    }
  }

  Future<bool> unassignDriver(int vehicleId) async {
    savingVehicleId.value = vehicleId;
    try {
      await _api.delete(ApiEndpoints.vehicleAssignDriver(vehicleId));
      _staffLoaded = false;
      await fetchVehicles();
      return true;
    } catch (e) {
      debugPrint('[Vehicles] unassign driver error: $e');
      return false;
    } finally {
      savingVehicleId.value = null;
    }
  }

  Future<bool> assignCleaner(int vehicleId, int userId) async {
    savingVehicleId.value = vehicleId;
    try {
      await _api.put(ApiEndpoints.vehicleAssignCleaner(vehicleId), data: {'userId': userId});
      _staffLoaded = false;
      await fetchVehicles();
      return true;
    } catch (e) {
      debugPrint('[Vehicles] assign cleaner error: $e');
      return false;
    } finally {
      savingVehicleId.value = null;
    }
  }

  Future<bool> unassignCleaner(int vehicleId) async {
    savingVehicleId.value = vehicleId;
    try {
      await _api.delete(ApiEndpoints.vehicleAssignCleaner(vehicleId));
      _staffLoaded = false;
      await fetchVehicles();
      return true;
    } catch (e) {
      debugPrint('[Vehicles] unassign cleaner error: $e');
      return false;
    } finally {
      savingVehicleId.value = null;
    }
  }
}
