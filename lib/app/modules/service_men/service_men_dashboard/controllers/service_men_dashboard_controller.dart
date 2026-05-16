import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = true.obs;
  final services  = <Map<String, dynamic>>[].obs;

  int get openCount       => services.where((s) => s['status'] == 'OPEN').length;
  int get inProgressCount => services.where((s) => s['status'] == 'IN_PROGRESS').length;

  Map<String, dynamic>? get activeService =>
      services.firstWhereOrNull((s) => s['status'] == 'IN_PROGRESS');

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.vehicleServices);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      services.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load services');
    }
    isLoading.value = false;
  }
}
