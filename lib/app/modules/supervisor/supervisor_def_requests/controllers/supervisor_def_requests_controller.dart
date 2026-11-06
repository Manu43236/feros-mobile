import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class SupervisorDefRequestsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading   = true.obs;
  final isSubmitting = false.obs;
  final requests    = <Map<String, dynamic>>[].obs;

  // Status filter: PENDING | ISSUED | REJECTED | ALL
  final filter = 'PENDING'.obs;
  List<Map<String, dynamic>> get filteredRequests => filter.value == 'ALL'
      ? requests
      : requests.where((r) => r['status'] == filter.value).toList();
  int get pendingCount => requests.where((r) => r['status'] == 'PENDING').length;

  // Vehicles + form state
  final vehicles          = <Map<String, dynamic>>[].obs;
  final selectedVehicleId = Rxn<int>();

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.consumableRequestsMy),
        _api.get(ApiEndpoints.vehicles),
      ]);
      final rRaw = (results[0].data as Map<String, dynamic>)['data'] as List? ?? [];
      requests.value = rRaw.cast<Map<String, dynamic>>();
      final vRaw = (results[1].data as Map<String, dynamic>)['data'] as List? ?? [];
      vehicles.value = vRaw.cast<Map<String, dynamic>>();
    } catch (_) {
      FerosSnackbar.error('Failed to load DEF requests');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    try {
      final res = await _api.get(ApiEndpoints.consumableRequestsMy);
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      requests.value = raw.cast<Map<String, dynamic>>();
    } catch (_) {
      FerosSnackbar.error('Failed to reload');
    }
  }

  void resetForm() {
    selectedVehicleId.value = null;
  }

  Future<bool> submitRequest(String notes) async {
    final vId = selectedVehicleId.value;
    if (vId == null) {
      FerosSnackbar.error('Select a vehicle');
      return false;
    }
    isSubmitting.value = true;
    try {
      await _api.post(ApiEndpoints.consumableRequests, data: {
        'vehicleId': vId,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
      FerosSnackbar.success('DEF request submitted');
      resetForm();
      await reload();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to submit request');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
