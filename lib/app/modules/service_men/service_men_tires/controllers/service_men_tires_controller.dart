import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenTiresController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoadingVehicles  = false.obs;
  final isLoadingPositions = false.obs;
  final isLoadingTires     = false.obs;
  final isSubmitting       = false.obs;

  final vehicles         = <Map<String, dynamic>>[].obs;
  final selectedVehicle  = Rxn<Map<String, dynamic>>();
  final positions        = <Map<String, dynamic>>[].obs;
  final availableTires   = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadVehicles();
    _loadAvailableTires();
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

  Future<void> _loadAvailableTires() async {
    isLoadingTires.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.tiresAvailable);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      availableTires.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load available tires');
    }
    isLoadingTires.value = false;
  }

  Future<void> selectVehicle(Map<String, dynamic> vehicle) async {
    selectedVehicle.value = vehicle;
    await _loadPositions(vehicle['id'] as int);
  }

  Future<void> _loadPositions(int vehicleId) async {
    isLoadingPositions.value = true;
    try {
      final res  = await _api.get(
        ApiEndpoints.tirePositionsCurrent,
        params: {'vehicleId': vehicleId},
      );
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      positions.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load tire positions');
    }
    isLoadingPositions.value = false;
  }

  Future<bool> fitTire({
    required int vehicleId,
    required int tireId,
    required int positionId,
    required String fittedDate,
    double? fittedAtKm,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.post(ApiEndpoints.tireFittings, data: {
        'vehicleId':  vehicleId,
        'tireId':     tireId,
        'positionId': positionId,
        'fittedDate': fittedDate,
        if (fittedAtKm != null) 'fittedAtKm': fittedAtKm,
      });
      await _loadPositions(vehicleId);
      await _loadAvailableTires();
      FerosSnackbar.success('Tire fitted successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to fit tire');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> removeTire({
    required int fittingId,
    required int vehicleId,
    required String removalReason,
    required String removedDate,
    double? removedAtKm,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.put(ApiEndpoints.tireFittingRemove(fittingId), data: {
        'removedDate':   removedDate,
        'removalReason': removalReason,
        if (removedAtKm != null) 'removedAtKm': removedAtKm,
      });
      await _loadPositions(vehicleId);
      await _loadAvailableTires();
      FerosSnackbar.success('Tire removed successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to remove tire');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
