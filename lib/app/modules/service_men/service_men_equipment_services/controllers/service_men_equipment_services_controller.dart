import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

/// SM equipment-services console — mirrors [ServiceMenServicesController] but for
/// equipment (machines). Equipment service endpoints are nested under the machine
/// id, so every mutation takes the equipmentId from the service map.
class ServiceMenEquipmentServicesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading   = true.obs;
  final services    = <Map<String, dynamic>>[].obs;
  final filter      = 'ALL'.obs;
  final technicians = <Map<String, dynamic>>[].obs;
  final taskTypes   = <Map<String, dynamic>>[].obs;
  final spareParts  = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get filteredServices {
    if (filter.value == 'ALL') return services;
    return services.where((s) => s['status'] == filter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchServices();
    _fetchMasters();
  }

  Future<void> fetchServices() async {
    isLoading.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.equipAllServices);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      services.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load services');
    }
    isLoading.value = false;
  }

  Future<void> _fetchMasters() async {
    try {
      final t = await _api.get(ApiEndpoints.serviceManagerTechnicians);
      technicians.assignAll(((t.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final tt = await _api.get(ApiEndpoints.equipServiceTaskTypes);
      taskTypes.assignAll(((tt.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final sp = await _api.get(ApiEndpoints.spareParts);
      spareParts.assignAll(((sp.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  int _equipIdOf(Map<String, dynamic> s) => s['equipmentId'] as int;

  Future<bool> startService(Map<String, dynamic> s) async {
    try {
      final res = await _api.post(ApiEndpoints.equipStartService(_equipIdOf(s), s['id']));
      _updateLocal(s['id'], (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
      FerosSnackbar.success('Service started');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to start service');
      return false;
    }
  }

  Future<Map<String, dynamic>?> completeService(
    Map<String, dynamic> s, {
    required String completedDate,
    double? completedHmr,
    double? completedCost,
  }) async {
    try {
      final data = <String, dynamic>{'completedDate': completedDate};
      if (completedHmr != null) data['completedHmr'] = completedHmr;
      if (completedCost != null) data['completedCost'] = completedCost;
      final res = await _api.post(ApiEndpoints.equipCompleteService(_equipIdOf(s), s['id']), data: data);
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(s['id'], updated);
      FerosSnackbar.success('Service completed');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to complete service');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addTask(
    Map<String, dynamic> s, {
    int? taskTypeId,
    String? customName,
    double? cost,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (taskTypeId != null) data['taskTypeId'] = taskTypeId;
      if (customName != null && customName.isNotEmpty) data['customName'] = customName;
      if (cost != null) data['cost'] = cost;
      final res = await _api.post(ApiEndpoints.equipAddServiceTask(_equipIdOf(s), s['id']), data: data);
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(s['id'], updated);
      FerosSnackbar.success('Task added');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to add task');
      return null;
    }
  }

  Future<Map<String, dynamic>?> assignTechnician(
    Map<String, dynamic> s, {
    required int taskId,
    required int technicianId,
  }) async {
    try {
      final res = await _api.put(
        ApiEndpoints.equipAssignServiceTask(_equipIdOf(s), s['id'], taskId),
        data: {'mechanicId': technicianId},
      );
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(s['id'], updated);
      FerosSnackbar.success('Technician assigned');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to assign technician');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchServiceParts(Map<String, dynamic> s) async {
    try {
      final res = await _api.get(ApiEndpoints.equipServiceParts(_equipIdOf(s), s['id']));
      return ((res.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> requestPart(
    Map<String, dynamic> s, {
    required int sparePartId,
    required int quantity,
    int? taskId,
  }) async {
    try {
      final data = <String, dynamic>{'sparePartId': sparePartId, 'quantityRequested': quantity};
      if (taskId != null) data['taskId'] = taskId;
      await _api.post(ApiEndpoints.equipRequestServicePart(_equipIdOf(s), s['id']), data: data);
      FerosSnackbar.success('Part requested successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to request part');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateCharges(Map<String, dynamic> s, double? estimatedCost) async {
    try {
      final res = await _api.put(
        ApiEndpoints.equipServiceCharges(_equipIdOf(s), s['id']),
        data: {'estimatedCost': estimatedCost},
      );
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(s['id'], updated);
      FerosSnackbar.success('Estimated cost saved');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to save cost');
      return null;
    }
  }

  Future<bool> addVendorItem(Map<String, dynamic> s, {required String description, double? cost}) async {
    try {
      final data = <String, dynamic>{'description': description};
      if (cost != null) data['cost'] = cost;
      await _api.post(ApiEndpoints.equipServiceVendorItems(_equipIdOf(s), s['id']), data: data);
      FerosSnackbar.success('Item added');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to add item');
      return false;
    }
  }

  Future<bool> deleteVendorItem(Map<String, dynamic> s, int itemId) async {
    try {
      await _api.delete(ApiEndpoints.equipServiceVendorItemById(_equipIdOf(s), s['id'], itemId));
      FerosSnackbar.success('Item removed');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to remove item');
      return false;
    }
  }

  /// Re-fetch the whole list and return the fresh copy of [id] (equipment has no
  /// single-service GET endpoint).
  Future<Map<String, dynamic>?> refreshService(int id) async {
    await fetchServices();
    final idx = services.indexWhere((s) => s['id'] == id);
    return idx != -1 ? services[idx] : null;
  }

  void _updateLocal(int id, Map<String, dynamic> updated) {
    final idx = services.indexWhere((s) => s['id'] == id);
    if (idx != -1) services[idx] = updated;
  }
}
