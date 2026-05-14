import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorOrderDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.loading.obs;
  final order = Rxn<Map<String, dynamic>>();

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int;
    fetchOrder();
  }

  Future<void> fetchOrder() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.orderById(orderId));
      order.value = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
