import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorActiveTripsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.loading.obs;
  final lrs   = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.lrs);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      lrs.assignAll(
        list.where((lr) => lr['lrStatus'] == 'IN_TRANSIT').toList(),
      );
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[ActiveTrips] $e');
      state.value = ViewState.error;
    }
  }

}
