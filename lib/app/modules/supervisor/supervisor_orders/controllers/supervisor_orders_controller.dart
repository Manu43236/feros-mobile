import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorOrdersController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state          = ViewState.loading.obs;
  final searchQuery    = ''.obs;
  final selectedFilters = <String>{'ALL'}.obs;

  final _allOrders = <Map<String, dynamic>>[].obs;
  final orders     = <Map<String, dynamic>>[].obs;

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
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.orders);
      final list = (res.data as Map<String, dynamic>)['data'] as List;
      final parsed = list.cast<Map<String, dynamic>>();
      parsed.sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
      _allOrders.value = parsed;
      _apply();
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  void toggleFilter(String filter) {
    if (filter == 'ALL') {
      selectedFilters.value = {'ALL'};
    } else {
      final current = Set<String>.from(selectedFilters);
      current.remove('ALL');
      if (current.contains(filter)) {
        current.remove(filter);
        if (current.isEmpty) current.add('ALL');
      } else {
        current.add(filter);
      }
      selectedFilters.value = current;
    }
    _apply();
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _apply();
  }

  void _apply() {
    List<Map<String, dynamic>> result = List.from(_allOrders);

    // Status filter
    if (!selectedFilters.contains('ALL')) {
      result = result.where((o) => selectedFilters.contains(o['orderStatus'])).toList();
    }

    // Search
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((o) {
        final num    = (o['orderNumber']  as String? ?? '').toLowerCase();
        final client = (o['clientName']   as String? ?? '').toLowerCase();
        final from   = (o['sourceCityName']      as String? ?? '').toLowerCase();
        final to     = (o['destinationCityName'] as String? ?? '').toLowerCase();
        return num.contains(q) || client.contains(q) || from.contains(q) || to.contains(q);
      }).toList();
    }

    orders.value = result;
  }
}
