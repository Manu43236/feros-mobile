import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorActiveTripsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state           = ViewState.loading.obs;
  final lrs             = <Map<String, dynamic>>[].obs;
  final proofsRefresher = 0.obs; // incremented to trigger Obx rebuilds

  final _proofsMap     = <int, List<Map<String, dynamic>>>{};
  final _proofsLoading = <int, bool>{};
  final _proofsLoaded  = <int, bool>{};

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

  List<Map<String, dynamic>> proofsFor(int lrId) => _proofsMap[lrId] ?? [];
  bool isProofsLoading(int lrId) => _proofsLoading[lrId] ?? false;
  bool isProofsLoaded(int lrId)  => _proofsLoaded[lrId]  ?? false;

  Future<void> loadProofs(int lrId) async {
    if (_proofsLoaded[lrId] == true) return;
    _proofsLoading[lrId] = true;
    proofsRefresher.value++;
    try {
      final res  = await _api.get(ApiEndpoints.tripProofsByLr(lrId));
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      _proofsMap[lrId]    = list;
      _proofsLoaded[lrId] = true;
    } catch (_) {
      _proofsMap[lrId]    = [];
      _proofsLoaded[lrId] = true;
    }
    _proofsLoading[lrId] = false;
    proofsRefresher.value++;
  }
}
