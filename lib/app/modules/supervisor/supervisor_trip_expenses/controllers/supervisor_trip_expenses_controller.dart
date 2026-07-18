import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorTripExpensesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final expenses     = <Map<String, dynamic>>[].obs;
  final activeFilter = 'ALL'.obs;

  static const filters = ['ALL', 'DRAFT', 'SUBMITTED', 'APPROVED', 'SETTLED', 'REJECTED'];

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    state.value = ViewState.loading;
    try {
      final params = activeFilter.value == 'ALL' ? <String, dynamic>{} : {'status': activeFilter.value};
      final res  = await _api.get(ApiEndpoints.tripExpenses, params: params);
      final list = ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      expenses.assignAll(list);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[TripExpenses] $e');
      state.value = ViewState.error;
    }
  }

  void setFilter(String filter) {
    if (activeFilter.value == filter) return;
    activeFilter.value = filter;
    fetchExpenses();
  }
}
