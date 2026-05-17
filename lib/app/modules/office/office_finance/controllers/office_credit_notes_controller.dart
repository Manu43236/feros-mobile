import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeCreditNotesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state       = ViewState.initial.obs;
  final creditNotes = <Map<String, dynamic>>[].obs;
  final filtered    = <Map<String, dynamic>>[].obs;

  final selectedStatus = 'ALL'.obs;

  static const statuses      = ['ALL', 'DRAFT', 'APPROVED', 'ADJUSTED'];
  static const statusLabels  = {
    'ALL':      'All',
    'DRAFT':    'Draft',
    'APPROVED': 'Approved',
    'ADJUSTED': 'Adjusted',
  };

  @override
  void onInit() {
    super.onInit();
    fetchCreditNotes();
    ever(selectedStatus, (_) => _applyFilter());
  }

  Future<void> fetchCreditNotes() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.creditNotes);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      creditNotes.value = data;
      _applyFilter();
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeCreditNotes] $e');
      state.value = ViewState.error;
    }
  }

  void _applyFilter() {
    final s = selectedStatus.value;
    filtered.value = s == 'ALL'
        ? creditNotes
        : creditNotes.where((cn) => cn['status'] == s).toList();
  }

  void setStatus(String s) => selectedStatus.value = s;
}
