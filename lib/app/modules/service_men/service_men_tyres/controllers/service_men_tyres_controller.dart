import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenTyresController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoadingVehicles  = false.obs;
  final isLoadingPositions = false.obs;
  final isLoadingTyres     = false.obs;
  final isSubmitting       = false.obs;

  final vehicles             = <Map<String, dynamic>>[].obs;
  final selectedVehicle      = Rxn<Map<String, dynamic>>();
  final positions            = <Map<String, dynamic>>[].obs;
  final availableTyres       = <Map<String, dynamic>>[].obs;
  final requireTyreApproval  = false.obs;
  final myTyreRequests       = <Map<String, dynamic>>[].obs;
  final isLoadingMyRequests  = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadVehicles();
    _loadAvailableTyres();
    _loadSettings();
    fetchMyRequests();
  }

  Future<void> fetchMyRequests() async {
    isLoadingMyRequests.value = true;
    try {
      final res = await _api.get(ApiEndpoints.tyreRequestsMy);
      myTyreRequests.value =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {}
    isLoadingMyRequests.value = false;
  }

  Future<void> _loadSettings() async {
    try {
      final res = await _api.get(ApiEndpoints.tenantSettings);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      requireTyreApproval.value = data?['requireTyreApproval'] == true;
    } catch (_) {
      requireTyreApproval.value = false;
    }
  }

  Future<void> _loadVehicles() async {
    isLoadingVehicles.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.vehicles);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      vehicles.assignAll(list.where((v) => v['isActive'] == true).toList());
    } catch (_) {
      FerosSnackbar.error('Failed to load vehicles');
    }
    isLoadingVehicles.value = false;
  }

  Future<void> _loadAvailableTyres() async {
    isLoadingTyres.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.tyresAvailable);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      availableTyres.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load available tyres');
    }
    isLoadingTyres.value = false;
  }

  Future<void> selectVehicle(Map<String, dynamic> vehicle) async {
    selectedVehicle.value = vehicle;
    await _loadPositions(vehicle['id'] as int);
  }

  Future<void> _loadPositions(int vehicleId) async {
    isLoadingPositions.value = true;
    try {
      final res  = await _api.get(
        ApiEndpoints.tyrePositionsCurrent,
        params: {'vehicleId': vehicleId},
      );
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      positions.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load tyre positions');
    }
    isLoadingPositions.value = false;
  }

  Future<bool> fitTyre({
    required int vehicleId,
    required int tyreId,
    required int positionId,
    required String fittedDate,
    double? fittedAtKm,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.post(ApiEndpoints.tyreFittings, data: {
        'vehicleId':  vehicleId,
        'tyreId':     tyreId,
        'positionId': positionId,
        'fittedDate': fittedDate,
        if (fittedAtKm != null) 'fittedAtKm': fittedAtKm,
      });
      await _loadPositions(vehicleId);
      await _loadAvailableTyres();
      FerosSnackbar.success('Tyre fitted successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to fit tyre');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> requestTyre({
    required int vehicleId,
    required int positionId,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.post(ApiEndpoints.tyreRequests, data: {
        'vehicleId':  vehicleId,
        'positionId': positionId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      await fetchMyRequests();
      FerosSnackbar.success('Tyre request submitted — awaiting store keeper approval');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to submit tyre request');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> removeTyre({
    required int fittingId,
    required int vehicleId,
    required String removalReason,
    required String removedDate,
    double? removedAtKm,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.put(ApiEndpoints.tyreFittingRemove(fittingId), data: {
        'removedDate':   removedDate,
        'removalReason': removalReason,
        if (removedAtKm != null) 'removedAtKm': removedAtKm,
      });
      await _loadPositions(vehicleId);
      await _loadAvailableTyres();
      FerosSnackbar.success('Tyre removed successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to remove tyre');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
