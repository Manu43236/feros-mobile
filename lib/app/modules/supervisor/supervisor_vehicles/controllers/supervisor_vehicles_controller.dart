import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorVehiclesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state            = ViewState.loading.obs;
  final _allVehicles     = <Map<String, dynamic>>[].obs;
  final vehicles         = <Map<String, dynamic>>[].obs;
  final searchQuery      = ''.obs;
  final selectedStatus   = 'ALL'.obs;
  final searchController = TextEditingController();
  final activeTab      = 'all'.obs;          // 'all' | 'watchlist'
  final watchlistedIds = <int>{}.obs;

  final attendanceStatus = <int, String>{}.obs; // userId → 'APPROVED'|'PENDING'|…

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
    _fetchWatchlistIds();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final res = await _api.get(ApiEndpoints.attendance, params: {'date': today});
      final records = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      attendanceStatus.value = {
        for (final r in records)
          if (r['userId'] != null)
            r['userId'] as int: r['approvalStatus'] as String? ?? 'PENDING',
      };
    } catch (e) {
      debugPrint('[Vehicles] attendance fetch error (non-fatal): $e');
    }
  }

  Future<void> _fetchWatchlistIds() async {
    try {
      final res = await _api.get(ApiEndpoints.watchlistVehicleIds);
      final ids = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<int>();
      watchlistedIds.assignAll(ids.toSet());
    } catch (e) {
      debugPrint('[Vehicles] watchlist fetch error: $e');
    }
  }

  Future<void> toggleWatchlist(int vehicleId) async {
    final inWl = watchlistedIds.contains(vehicleId);
    final reg = _allVehicles
        .firstWhere((v) => v['id'] == vehicleId, orElse: () => {})['registrationNumber'] as String? ?? '';
    if (inWl) {
      watchlistedIds.remove(vehicleId);
    } else {
      watchlistedIds.add(vehicleId);
    }
    _apply();
    try {
      if (inWl) {
        await _api.delete(ApiEndpoints.watchlistVehicleById(vehicleId));
        FerosSnackbar.success(reg.isNotEmpty ? '$reg removed from watchlist' : 'Removed from watchlist');
      } else {
        await _api.post(ApiEndpoints.watchlistVehicles, data: {'vehicleId': vehicleId});
        FerosSnackbar.success(reg.isNotEmpty ? '$reg added to watchlist' : 'Added to watchlist');
      }
    } catch (e) {
      if (inWl) {
        watchlistedIds.add(vehicleId);
      } else {
        watchlistedIds.remove(vehicleId);
      }
      _apply();
      FerosSnackbar.error('Failed to update watchlist');
    }
  }

  void setTab(String tab) {
    activeTab.value = tab;
    searchQuery.value = '';
    searchController.clear();
    selectedStatus.value = 'ALL';
    _apply();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
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

    // Watchlist tab filter
    if (activeTab.value == 'watchlist') {
      list = list.where((v) => watchlistedIds.contains(v['id'] as int?)).toList();
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
