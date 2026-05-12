import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/view_state.dart';
import '../models/lr_model.dart';

class TripsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;
  final allLrs = <LrModel>[].obs;
  final filteredLrs = <LrModel>[].obs;
  final selectedFilter = 'All'.obs;
  final searchQuery = ''.obs;

  final filters = ['All', 'CREATED', 'WEIGHT_LOADED', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];

  @override
  void onReady() {
    super.onReady();
    fetchLrs();
  }

  Future<void> fetchLrs() async {
    state.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.lrs);
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];
      allLrs.value = list
          .map((e) => LrModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _applyFilter();
      state.value = allLrs.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      state.value = ViewState.error;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void onFilterChanged(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    var result = allLrs.toList();

    if (selectedFilter.value != 'All') {
      result = result
          .where((lr) => lr.lrStatus.toUpperCase() == selectedFilter.value)
          .toList();
    }

    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((lr) =>
          lr.lrNumber.toLowerCase().contains(q) ||
          lr.orderNumber.toLowerCase().contains(q) ||
          lr.clientName.toLowerCase().contains(q) ||
          lr.fromCity.toLowerCase().contains(q) ||
          lr.toCity.toLowerCase().contains(q) ||
          lr.vehicleNumber.toLowerCase().contains(q)).toList();
    }

    result.sort((a, b) => b.id.compareTo(a.id));
    filteredLrs.value = result;
  }
}
