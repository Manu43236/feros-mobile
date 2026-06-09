import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeStaffController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state      = ViewState.initial.obs;
  final staff      = <Map<String, dynamic>>[].obs;
  final filtered   = <Map<String, dynamic>>[].obs;

  final searchQuery    = ''.obs;
  final selectedRole   = 'ALL'.obs;

  static const roles = [
    'ALL', 'DRIVER', 'CLEANER', 'SUPERVISOR',
    'SERVICE_MANAGER', 'STORE_KEEPER', 'OFFICE_STAFF',
  ];

  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    fetchStaff();
    _searchWorker = debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );
    ever(selectedRole, (_) => _applyFilter());
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchStaff() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.users);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      staff.value = data;
      _applyFilter();
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeStaff] $e');
      state.value = ViewState.error;
    }
  }

  void _applyFilter() {
    var list = staff.toList();

    final role = selectedRole.value;
    if (role != 'ALL') {
      list = list.where((u) => u['role'] == role).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) {
        final name  = (u['name']  as String? ?? '').toLowerCase();
        final phone = (u['phone'] as String? ?? '').toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }

    filtered.value = list;
  }

  void onSearch(String q) => searchQuery.value = q;
  void setRole(String r)  => selectedRole.value = r;

  Future<void> createUser(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.users, data: body);
    await fetchStaff();
  }

  Future<String?> resetPin(int userId) async {
    final res = await _api.put('/users/$userId/reset-pin', data: {});
    final data = (res.data as Map)['data'] as Map?;
    return data?['pin'] as String?;
  }
}
