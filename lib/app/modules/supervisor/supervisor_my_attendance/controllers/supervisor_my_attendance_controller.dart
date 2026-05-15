import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorMyAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state   = ViewState.loading.obs;
  final records = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.myAttendance);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      records.assignAll(list);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[MyAttendance] $e');
      state.value = ViewState.error;
    }
  }
}
