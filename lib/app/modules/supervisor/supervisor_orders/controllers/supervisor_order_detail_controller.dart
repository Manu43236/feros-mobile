import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorOrderDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state   = ViewState.loading.obs;
  final order   = Rxn<Map<String, dynamic>>();
  final lrs     = <Map<String, dynamic>>[].obs;
  final invoices= <Map<String, dynamic>>[].obs;

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int;
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.orderById(orderId)),
        _api.get(ApiEndpoints.lrsByOrder(orderId)),
        _api.get(ApiEndpoints.invoicesByOrder(orderId)),
      ]);

      order.value = (results[0].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

      lrs.value = ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();

      invoices.value =
          ((results[2].data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>();

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
