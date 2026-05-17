import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeClientsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state      = ViewState.initial.obs;
  final clients    = <Map<String, dynamic>>[].obs;
  final filtered   = <Map<String, dynamic>>[].obs;

  final searchQuery    = ''.obs;
  final selectedFilter = 'ALL'.obs; // ALL | ACTIVE | INACTIVE

  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
    _searchWorker = debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );
    ever(selectedFilter, (_) => _applyFilter());
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchClients() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.clients);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      clients.value = data;
      _applyFilter();
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeClients] $e');
      state.value = ViewState.error;
    }
  }

  void _applyFilter() {
    var list = clients.toList();

    // Status filter
    final f = selectedFilter.value;
    if (f == 'ACTIVE')   list = list.where((c) => c['isActive'] == true).toList();
    if (f == 'INACTIVE') list = list.where((c) => c['isActive'] != true).toList();

    // Search
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name  = (c['clientName'] as String? ?? '').toLowerCase();
        final phone = (c['phone']      as String? ?? '').toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }

    filtered.value = list;
  }

  void onSearch(String q) => searchQuery.value = q;
  void setFilter(String f) => selectedFilter.value = f;
}
