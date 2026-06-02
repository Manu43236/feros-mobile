import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorLrsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state           = ViewState.loading.obs;
  final _lrs            = <Map<String, dynamic>>[].obs;
  final statusFilter    = ''.obs;
  final searchQuery     = ''.obs;
  final isLoadingMore   = false.obs;
  final hasMore         = true.obs;
  final totalCount      = 0.obs;

  int _page = 0;
  static const _pageSize = 20;
  late final ScrollController scrollController;

  // For Create LR sheet
  final orders     = <Map<String, dynamic>>[].obs;
  final isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController()..addListener(_onScroll);
    fetchLrs();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> fetchLrs() async {
    state.value = ViewState.loading;
    _page = 0;
    hasMore.value = true;
    _lrs.clear();
    try {
      final res   = await _api.get(ApiEndpoints.lrs, params: _buildParams(0));
      final body  = res.data as Map<String, dynamic>;
      final data  = body['data'] as Map<String, dynamic>;
      final list  = (data['content'] as List).cast<Map<String, dynamic>>();
      totalCount.value = data['totalElements'] as int? ?? 0;
      hasMore.value    = !(data['last'] as bool? ?? true);
      _lrs.assignAll(list);
      _page = 1;
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[LRs] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.lrs, params: _buildParams(_page));
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final list = (data['content'] as List).cast<Map<String, dynamic>>();
      hasMore.value = !(data['last'] as bool? ?? true);
      _lrs.addAll(list);
      _page++;
    } catch (e) {
      debugPrint('[LRs loadMore] $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Map<String, dynamic> _buildParams(int pageNum) {
    final params = <String, dynamic>{'page': pageNum, 'size': _pageSize};
    if (statusFilter.value.isNotEmpty) params['status'] = statusFilter.value;
    if (searchQuery.value.isNotEmpty)  params['search'] = searchQuery.value;
    return params;
  }

  List<Map<String, dynamic>> get lrs => _lrs;

  void onSearch(String v) { searchQuery.value = v; fetchLrs(); }
  void setFilter(String s) { statusFilter.value = s; fetchLrs(); }

  Future<void> ensureOrdersLoaded() async {
    if (orders.isNotEmpty) return;
    try {
      final res  = await _api.get(ApiEndpoints.orders);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      orders.assignAll(list.where((o) {
        final st = o['orderStatus'] as String? ?? '';
        return !['CANCELLED', 'DELIVERED'].contains(st);
      }).toList()
        ..sort((a, b) => ((b['id'] as int? ?? 0)
            .compareTo(a['id'] as int? ?? 0))));
    } catch (_) {}
  }

  Future<bool> createLr(Map<String, dynamic> data) async {
    isCreating.value = true;
    try {
      await _api.post(ApiEndpoints.lrs, data: data);
      FerosSnackbar.success('LR created');
      orders.clear(); // force reload next time
      await fetchLrs();
      isCreating.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to create LR');
      isCreating.value = false;
      return false;
    }
  }
}
