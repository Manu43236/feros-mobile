import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeInvoicesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state           = ViewState.initial.obs;
  final _invoices       = <Map<String, dynamic>>[].obs;
  final selectedStatus  = 'ALL'.obs;
  final isLoadingMore   = false.obs;
  final hasMore         = true.obs;
  final totalCount      = 0.obs;

  int _page = 0;
  static const _pageSize = 20;
  late final ScrollController scrollController;

  static const statuses = ['ALL', 'DRAFT', 'SENT', 'PARTIALLY_PAID', 'OVERDUE', 'PAID'];
  static const statusLabels = {
    'ALL':           'All',
    'DRAFT':         'Draft',
    'SENT':          'Sent',
    'PARTIALLY_PAID':'Part. Paid',
    'OVERDUE':       'Overdue',
    'PAID':          'Paid',
  };

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController()..addListener(_onScroll);
    fetchInvoices();
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

  Future<void> fetchInvoices() async {
    state.value = ViewState.loading;
    _page = 0;
    hasMore.value = true;
    _invoices.clear();
    try {
      final res  = await _api.get(ApiEndpoints.invoices, params: _buildParams(0));
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final list = (data['content'] as List).cast<Map<String, dynamic>>();
      totalCount.value = data['totalElements'] as int? ?? 0;
      hasMore.value    = !(data['last'] as bool? ?? true);
      _invoices.assignAll(list);
      _page = 1;
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInvoices] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.invoices, params: _buildParams(_page));
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final list = (data['content'] as List).cast<Map<String, dynamic>>();
      hasMore.value = !(data['last'] as bool? ?? true);
      _invoices.addAll(list);
      _page++;
    } catch (e) {
      debugPrint('[OfficeInvoices loadMore] $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Map<String, dynamic> _buildParams(int pageNum) {
    final params = <String, dynamic>{'page': pageNum, 'size': _pageSize};
    if (selectedStatus.value != 'ALL') params['status'] = selectedStatus.value;
    return params;
  }

  List<Map<String, dynamic>> get filtered => _invoices;

  void setStatus(String s) { selectedStatus.value = s; fetchInvoices(); }
}
