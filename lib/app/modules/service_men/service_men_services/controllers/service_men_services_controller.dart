import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenServicesController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = true.obs;
  final services  = <Map<String, dynamic>>[].obs;
  final filter    = 'ALL'.obs;

  List<Map<String, dynamic>> get filteredServices {
    if (filter.value == 'ALL') return services;
    return services.where((s) => s['status'] == filter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  Future<void> fetchServices() async {
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

  Future<bool> startService(int id) async {
    try {
      final res     = await _api.put(ApiEndpoints.startService(id));
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(id, updated);
      FerosSnackbar.success('Service started');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to start service');
      return false;
    }
  }

  Future<bool> completeService(int id,
      {required String completedDate, int? odometer}) async {
    try {
      final res = await _api.put(ApiEndpoints.completeService(id), data: {
        'completedDate': completedDate,
        if (odometer != null) 'odometer': odometer,
      });
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(id, updated);
      FerosSnackbar.success('Service completed');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to complete service');
      return false;
    }
  }

  Future<Map<String, dynamic>?> completeTask(int serviceId, int taskId) async {
    try {
      final res     = await _api.patch(ApiEndpoints.completeTask(serviceId, taskId));
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(serviceId, updated);
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to update task');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchServiceParts(int serviceId) async {
    try {
      final res = await _api.get(ApiEndpoints.servicePartsByService(serviceId));
      return ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> requestPart({
    required int serviceId,
    required int sparePartId,
    required int quantity,
  }) async {
    try {
      await _api.post(ApiEndpoints.requestServicePart(serviceId), data: {
        'sparePartId':         sparePartId,
        'quantityRequested':   quantity,
      });
      FerosSnackbar.success('Part requested successfully');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to request part');
      return false;
    }
  }

  void _updateLocal(int id, Map<String, dynamic> updated) {
    final idx = services.indexWhere((s) => s['id'] == id);
    if (idx != -1) services[idx] = updated;
  }
}
