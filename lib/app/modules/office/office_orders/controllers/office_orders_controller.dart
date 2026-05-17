import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeOrdersController extends GetxController {
  final _api = Get.find<ApiClient>();

  static const _pageSize = 20;

  final state           = ViewState.loading.obs;
  final searchQuery     = ''.obs;
  final selectedFilters = <String>{'ALL'}.obs;

  final orders        = <Map<String, dynamic>>[].obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;

  int _currentPage = 0;

  Worker? _searchWorker;

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
    fetchOrders(reset: true);
    _searchWorker = debounce(
      searchQuery,
      (_) => fetchOrders(reset: true),
      time: const Duration(milliseconds: 400),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchOrders({bool reset = false}) async {
    if (reset) {
      _currentPage  = 0;
      hasMore.value = true;
      state.value   = ViewState.loading;
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'size': _pageSize,
      };
      final q = searchQuery.value.trim();
      if (q.isNotEmpty) params['search'] = q;
      if (!selectedFilters.contains('ALL')) {
        params['status'] = selectedFilters.first;
      }

      final res  = await _api.get(ApiEndpoints.orders, params: params);
      final page = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      final content = (page['content'] as List).cast<Map<String, dynamic>>();
      hasMore.value = !((page['last'] as bool?) ?? true);

      if (reset) {
        orders.value = content;
      } else {
        orders.addAll(content);
      }
      _currentPage++;
      state.value = ViewState.success;
    } catch (_) {
      if (reset) state.value = ViewState.error;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() => fetchOrders(reset: false);

  void toggleFilter(String filter) {
    if (filter == 'ALL') {
      selectedFilters.assignAll({'ALL'});
    } else {
      final current = Set<String>.from(selectedFilters);
      current.remove('ALL');
      if (current.contains(filter)) {
        current.remove(filter);
        if (current.isEmpty) current.add('ALL');
      } else {
        current.add(filter);
      }
      selectedFilters.assignAll(current);
    }
    fetchOrders(reset: true);
  }

  void onSearch(String query) => searchQuery.value = query;
}
