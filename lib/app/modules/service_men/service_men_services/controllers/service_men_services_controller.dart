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

  Future<Map<String, dynamic>?> completeService(
    int id, {
    required String completedDate,
    int? odometer,
    double? labourCharges,
    double? vendorAmount,
    String? vendorInvoiceNo,
  }) async {
    try {
      final data = <String, dynamic>{'completedDate': completedDate};
      if (odometer != null) data['odometer'] = odometer;
      if (labourCharges != null) data['labourCharges'] = labourCharges;
      if (vendorAmount != null) data['vendorAmount'] = vendorAmount;
      if (vendorInvoiceNo != null && vendorInvoiceNo.isNotEmpty) data['vendorInvoiceNo'] = vendorInvoiceNo;
      final res = await _api.put(ApiEndpoints.completeService(id), data: data);
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(id, updated);
      FerosSnackbar.success('Service completed');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to complete service');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchInvoice(int serviceId) async {
    try {
      final res = await _api.get(ApiEndpoints.serviceInvoiceByService(serviceId));
      return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> downloadInvoicePdf(int invoiceId) async {
    try {
      return await _api.getBytes(ApiEndpoints.serviceInvoicePdf(invoiceId));
    } catch (_) {
      FerosSnackbar.error('Failed to load PDF');
      return null;
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

  Future<Map<String, dynamic>?> addTask(
    int serviceId, {
    int? taskTypeId,
    String? customName,
    double? cost,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (taskTypeId != null) data['taskTypeId'] = taskTypeId;
      if (customName != null && customName.isNotEmpty) data['customName'] = customName;
      if (cost != null) data['cost'] = cost;
      final res = await _api.post(ApiEndpoints.addServiceTask(serviceId), data: data);
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(serviceId, updated);
      FerosSnackbar.success('Task added');
      return updated;
    } catch (_) {
      FerosSnackbar.error('Failed to add task');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchServiceById(int id) async {
    try {
      final res = await _api.get(ApiEndpoints.vehicleServiceById(id));
      final updated = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      _updateLocal(id, updated);
      return updated;
    } catch (_) {
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

  Future<Map<String, dynamic>?> createService({
    required int vehicleId,
    required String triggeredBy,
    required String serviceType,
    required String payerType,
    required String serviceDate,
    String? vendorName,
    String? location,
    int? odometer,
    String? notes,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      final res = await _api.post(ApiEndpoints.vehicleServices, data: {
        'vehicleId':   vehicleId,
        'triggeredBy': triggeredBy,
        'serviceType': serviceType,
        'payerType':   payerType,
        'serviceDate': serviceDate,
        if (vendorName != null && vendorName.isNotEmpty) 'vendorName': vendorName,
        if (location   != null && location.isNotEmpty)   'location':   location,
        if (odometer   != null)                          'odometer':   odometer,
        if (notes      != null && notes.isNotEmpty)      'notes':      notes,
        'tasks': tasks,
      });
      final created = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      services.insert(0, created);
      FerosSnackbar.success('Service created');
      return created;
    } catch (_) {
      FerosSnackbar.error('Failed to create service');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addVendorItem(
    int serviceId, {
    required String description,
    double? cost,
  }) async {
    try {
      final data = <String, dynamic>{'description': description};
      if (cost != null) data['cost'] = cost;
      final res = await _api.post(ApiEndpoints.vendorItems(serviceId), data: data);
      return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } catch (_) {
      FerosSnackbar.error('err_failed_add_part'.tr);
      return null;
    }
  }

  Future<bool> deleteVendorItem(int serviceId, int itemId) async {
    try {
      await _api.delete(ApiEndpoints.vendorItemById(serviceId, itemId));
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to remove item');
      return false;
    }
  }

  void _updateLocal(int id, Map<String, dynamic> updated) {
    final idx = services.indexWhere((s) => s['id'] == id);
    if (idx != -1) services[idx] = updated;
  }
}
