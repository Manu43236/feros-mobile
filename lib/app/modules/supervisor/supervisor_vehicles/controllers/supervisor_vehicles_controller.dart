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
}
