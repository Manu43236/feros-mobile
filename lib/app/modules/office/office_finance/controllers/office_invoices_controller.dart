import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeInvoicesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state    = ViewState.initial.obs;
  final invoices = <Map<String, dynamic>>[].obs;
  final filtered = <Map<String, dynamic>>[].obs;

  final selectedStatus = 'ALL'.obs;

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
    fetchInvoices();
    ever(selectedStatus, (_) => _applyFilter());
  }

  Future<void> fetchInvoices() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.invoices);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      invoices.value = data;
      _applyFilter();
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInvoices] $e');
      state.value = ViewState.error;
    }
  }

  void _applyFilter() {
    final s = selectedStatus.value;
    if (s == 'ALL') {
      filtered.value = invoices;
    } else {
      filtered.value = invoices.where((inv) => inv['invoiceStatus'] == s).toList();
    }
  }

  void setStatus(String s) => selectedStatus.value = s;
}
