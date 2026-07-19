import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorCrewController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state             = ViewState.loading.obs;
  final _allCrew          = <Map<String, dynamic>>[].obs;
  final attendanceStatus  = <int, String>{}.obs; // userId → 'PRESENT'|'PENDING'|'REJECTED'
  final searchQuery       = ''.obs;
  final roleFilter        = 'ALL'.obs;
  final statusFilter      = 'ALL'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCrew();
  }

  Future<void> fetchCrew() async {
    state.value = ViewState.loading;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final results = await Future.wait([
        _api.get(ApiEndpoints.users),
        _api.get(ApiEndpoints.attendance, params: {'date': today}),
      ]);

      final all = ((results[0].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      _allCrew.assignAll(all.where((u) {
        final role = u['role'] as String? ?? '';
        return role == 'DRIVER' || role == 'CLEANER';
      }).toList()
        ..sort((a, b) => ((a['name'] as String?) ?? '')
            .compareTo((b['name'] as String?) ?? '')));

      final records = ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      attendanceStatus.value = {
        for (final r in records)
          if (r['userId'] != null)
            r['userId'] as int: r['approvalStatus'] as String? ?? 'PENDING',
      };

      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Crew] fetch error: $e');
      state.value = ViewState.error;
    }
  }

  List<Map<String, dynamic>> get crew {
    final q      = searchQuery.value.toLowerCase();
    final role   = roleFilter.value;
    final status = statusFilter.value;
    return _allCrew.where((u) {
      final name      = (u['name']  as String? ?? '').toLowerCase();
      final phone     = (u['phone'] as String? ?? '');
      final r         = (u['role']  as String? ?? '');
      final isActive  = u['isActive']  as bool? ?? false;
      final isAssigned = u['isAssigned'] as bool? ?? false;

      final matchSearch = q.isEmpty || name.contains(q) || phone.contains(q);
      final matchRole   = role == 'ALL' || r == role;
      final matchStatus = switch (status) {
        'AVAILABLE' => isActive && !isAssigned,
        'ON_TRIP'   => isActive && isAssigned,
        'INACTIVE'  => !isActive,
        _           => true,
      };
      return matchSearch && matchRole && matchStatus;
    }).toList();
  }

  int get driverCount  => _allCrew.where((u) => u['role'] == 'DRIVER').length;
  int get cleanerCount => _allCrew.where((u) => u['role'] == 'CLEANER').length;
  int get availableCount => _allCrew.where((u) =>
      (u['isActive'] as bool? ?? false) &&
      !(u['isAssigned'] as bool? ?? false)).length;
  int get onTripCount => _allCrew.where((u) =>
      (u['isActive'] as bool? ?? false) &&
      (u['isAssigned'] as bool? ?? false)).length;

  void onSearch(String v)       => searchQuery.value  = v;
  void onRoleFilter(String v)   => roleFilter.value   = v;
  void onStatusFilter(String v) => statusFilter.value = v;
}
