import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorOrdersController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.initial.obs;
  final selectedFilter = 'ALL'.obs;

  final _allOrders   = <Map<String, dynamic>>[].obs;
  final orders       = <Map<String, dynamic>>[].obs;

  static const filters = [
    'ALL',
    'PENDING',
    'PARTIALLY_ASSIGNED',
    'FULLY_ASSIGNED',
    'IN_TRANSIT',
    'PARTIALLY_DELIVERED',
    'DELIVERED',
    'CANCELLED',
  ];

  static const filterLabels = {
    'ALL':                 'All',
    'PENDING':             'Pending',
    'PARTIALLY_ASSIGNED':  'Part. Assigned',
    'FULLY_ASSIGNED':      'Assigned',
    'IN_TRANSIT':          'In Transit',
    'PARTIALLY_DELIVERED': 'Part. Delivered',
    'DELIVERED':           'Delivered',
    'CANCELLED':           'Cancelled',
  };

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.orders);
      final list = (res.data as Map<String, dynamic>)['data'] as List;
      _allOrders.value = list.cast<Map<String, dynamic>>();
      _applyFilter();
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedFilter.value == 'ALL') {
      orders.value = List.from(_allOrders);
    } else {
      orders.value = _allOrders
          .where((o) => o['orderStatus'] == selectedFilter.value)
          .toList();
    }
  }
}
