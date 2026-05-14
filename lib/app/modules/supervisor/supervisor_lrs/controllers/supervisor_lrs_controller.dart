import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorLrsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final _allLrs      = <Map<String, dynamic>>[].obs;
  final statusFilter = ''.obs;
  final searchQuery  = ''.obs;

  // For Create LR sheet
  final orders     = <Map<String, dynamic>>[].obs;
  final isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLrs();
  }

  Future<void> fetchLrs() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.lrs);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      list.sort((a, b) {
        final aId = a['id'] as int? ?? 0;
        final bId = b['id'] as int? ?? 0;
        return bId.compareTo(aId);
      });
      _allLrs.assignAll(list);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[LRs] $e');
      state.value = ViewState.error;
    }
  }

  List<Map<String, dynamic>> get lrs {
    final status = statusFilter.value;
    final q      = searchQuery.value.toLowerCase();
    return _allLrs.where((lr) {
      final matchStatus = status.isEmpty || lr['lrStatus'] == status;
      if (!matchStatus) return false;
      if (q.isEmpty) return true;
      return (lr['lrNumber']                  as String? ?? '').toLowerCase().contains(q) ||
             (lr['orderNumber']               as String? ?? '').toLowerCase().contains(q) ||
             (lr['vehicleRegistrationNumber'] as String? ?? '').toLowerCase().contains(q) ||
             (lr['clientName']               as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int get totalCount => _allLrs.length;

  int countByStatus(String s) =>
      _allLrs.where((lr) => lr['lrStatus'] == s).length;

  void onSearch(String v) => searchQuery.value = v;
  void setFilter(String s) => statusFilter.value = s;

  Future<void> ensureOrdersLoaded() async {
    if (orders.isNotEmpty) return;
    try {
      final res  = await _api.get(ApiEndpoints.orders);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      orders.assignAll(list.where((o) {
        final st = o['orderStatus'] as String? ?? '';
        return !['CANCELLED', 'DELIVERED'].contains(st);
      }).toList()
        ..sort((a, b) => ((b['id'] as int? ?? 0)
            .compareTo(a['id'] as int? ?? 0))));
    } catch (_) {}
  }

  Future<bool> createLr(Map<String, dynamic> data) async {
    isCreating.value = true;
    try {
      await _api.post(ApiEndpoints.lrs, data: data);
      FerosSnackbar.success('LR created');
      orders.clear(); // force reload next time
      await fetchLrs();
      isCreating.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to create LR');
      isCreating.value = false;
      return false;
    }
  }
}
