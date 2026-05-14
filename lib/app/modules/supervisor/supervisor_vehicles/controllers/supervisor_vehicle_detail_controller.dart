import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorVehicleDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state   = ViewState.loading.obs;
  final vehicle = Rxn<Map<String, dynamic>>();

  late final int vehicleId;

  @override
  void onInit() {
    super.onInit();
    vehicleId = Get.arguments as int;
    fetchVehicle();
  }

  Future<void> fetchVehicle() async {
    state.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicleById(vehicleId));
      vehicle.value =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }
}
