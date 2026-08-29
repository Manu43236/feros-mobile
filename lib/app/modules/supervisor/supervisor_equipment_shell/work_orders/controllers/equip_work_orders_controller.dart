import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/utils/view_state.dart';

class EquipWorkOrdersController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state          = ViewState.loading.obs;
  final workOrders     = <Map<String, dynamic>>[].obs;
  final selectedStatus = 'ALL'.obs;

  static const statuses = [
    'ALL',
    'DRAFT',
    'CONFIRMED',
    'IN_PROGRESS',
    'COMPLETED',
    'INVOICED',
    'CANCELLED',
  ];

  static const statusLabels = {
    'ALL':        'All',
    'DRAFT':      'Draft',
    'CONFIRMED':  'Confirmed',
    'IN_PROGRESS':'In Progress',
    'COMPLETED':  'Completed',
    'INVOICED':   'Invoiced',
    'CANCELLED':  'Cancelled',
  };

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final params = <String, dynamic>{'page': 0, 'size': 100};
      final s = selectedStatus.value;
      if (s != 'ALL') params['status'] = s;

      final res  = await _api.get(ApiEndpoints.equipWorkOrders, params: params);
      final page = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      workOrders.value = (page['content'] as List).cast<Map<String, dynamic>>();
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  void selectStatus(String status) {
    if (selectedStatus.value == status) return;
    selectedStatus.value = status;
    fetchAll();
  }
}
