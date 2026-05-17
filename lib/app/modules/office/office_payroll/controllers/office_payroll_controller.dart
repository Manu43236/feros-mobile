import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficePayrollController extends GetxController {
  final _api = Get.find<ApiClient>();

  final payrollState  = ViewState.initial.obs;
  final advanceState  = ViewState.initial.obs;

  final payrolls      = <Map<String, dynamic>>[].obs;
  final filteredPayrolls = <Map<String, dynamic>>[].obs;
  final advances      = <Map<String, dynamic>>[].obs;

  final selectedStatus = 'ALL'.obs;

  static const statuses = ['ALL', 'DRAFT', 'APPROVED', 'PAID', 'CANCELLED'];

  @override
  void onInit() {
    super.onInit();
    fetchPayrolls();
    fetchAdvances();
    ever(selectedStatus, (_) => _applyFilter());
  }

  Future<void> fetchPayrolls() async {
    payrollState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.payroll);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      payrolls.value = data;
      _applyFilter();
      payrollState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficePayroll] payrolls: $e');
      payrollState.value = ViewState.error;
    }
  }

  Future<void> fetchAdvances() async {
    advanceState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.payrollAdvances);
      advances.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      advanceState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficePayroll] advances: $e');
      advanceState.value = ViewState.error;
    }
  }

  void _applyFilter() {
    final s = selectedStatus.value;
    filteredPayrolls.value = s == 'ALL'
        ? payrolls.toList()
        : payrolls.where((p) => p['payrollStatus'] == s).toList();
  }

  void setStatus(String s) => selectedStatus.value = s;

  Future<void> generatePayroll(Map<String, dynamic> body) async {
    await _api.post('/payroll/generate', data: body);
    await fetchPayrolls();
  }

  Future<void> approvePayroll(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.approvePayroll(id), data: body);
    await fetchPayrolls();
  }

  Future<void> cancelPayroll(int id) async {
    await _api.delete(ApiEndpoints.payrollById(id));
    await fetchPayrolls();
  }

  Future<void> createAdvance(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.payrollAdvances, data: body);
    await fetchAdvances();
  }
}
