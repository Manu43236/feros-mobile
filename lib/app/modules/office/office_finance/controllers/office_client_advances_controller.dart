import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeClientAdvancesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state    = ViewState.initial.obs;
  final advances = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdvances();
  }

  Future<void> fetchAdvances() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.clientAdvances);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      advances.value = data;
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeClientAdvances] $e');
      state.value = ViewState.error;
    }
  }
}
