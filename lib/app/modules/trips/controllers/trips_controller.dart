import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/view_state.dart';
import '../models/trip_model.dart';

class TripsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;
  final allTrips = <TripModel>[].obs;
  final filteredTrips = <TripModel>[].obs;
  final selectedFilter = 'All'.obs;
  final searchQuery = ''.obs;
  final isUpdating = false.obs;

  final filters = ['All', 'PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];

  @override
  void onReady() {
    super.onReady();
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    state.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.orders);
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];
      allTrips.value = list
          .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _applyFilter();
      state.value = allTrips.isEmpty ? ViewState.empty : ViewState.success;
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
    var result = allTrips.toList();

    // status filter
    if (selectedFilter.value != 'All') {
      result = result
          .where((t) => t.status.toUpperCase() == selectedFilter.value)
          .toList();
    }

    // search
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((t) =>
          t.orderNumber.toLowerCase().contains(q) ||
          t.clientName.toLowerCase().contains(q) ||
          t.fromLocation.toLowerCase().contains(q) ||
          t.toLocation.toLowerCase().contains(q) ||
          (t.lrNumber?.toLowerCase().contains(q) ?? false)).toList();
    }

    filteredTrips.value = result;
  }
}
