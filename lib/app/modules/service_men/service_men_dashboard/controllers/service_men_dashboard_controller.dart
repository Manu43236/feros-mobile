import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading     = true.obs;
  final isAssigning   = false.obs;

  // SM dashboard data
  final breakdowns      = <Map<String, dynamic>>[].obs;
  final generalServices = <Map<String, dynamic>>[].obs;
  final technicians     = <Map<String, dynamic>>[].obs;

  int get breakdownCount    => breakdowns.length;
  int get serviceCount      => generalServices.length;
  int get technicianCount   => technicians.length;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    await Future.wait([_fetchDashboard(), _fetchTechnicians()]);
    isLoading.value = false;
  }

  Future<void> _fetchDashboard() async {
    try {
      final res  = await _api.get(ApiEndpoints.serviceManagerDashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      breakdowns.assignAll(
        ((data['breakdowns'] as List?) ?? []).cast<Map<String, dynamic>>(),
      );
      generalServices.assignAll(
        ((data['generalServices'] as List?) ?? []).cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      FerosSnackbar.error('Failed to load dashboard');
    }
  }

  Future<void> _fetchTechnicians() async {
    try {
      final res  = await _api.get(ApiEndpoints.serviceManagerTechnicians);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      technicians.assignAll(list);
    } catch (_) {
      // non-critical — silently ignore
    }
  }

  Future<bool> assignTechnician({
    required int serviceId,
    required int taskId,
    required int technicianId,
  }) async {
    isAssigning.value = true;
    try {
      await _api.put(
        ApiEndpoints.assignTechnicianToTask(serviceId, taskId),
        data: {'mechanicId': technicianId},
      );
      FerosSnackbar.success('Technician assigned');
      await _fetchDashboard();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to assign technician');
      return false;
    } finally {
      isAssigning.value = false;
    }
  }

  Future<bool> completeService({
    required int serviceId,
    required String completedDate,
    int? odometer,
  }) async {
    try {
      final data = <String, dynamic>{'completedDate': completedDate};
      if (odometer != null) data['odometer'] = odometer;
      await _api.put(ApiEndpoints.completeService(serviceId), data: data);
      FerosSnackbar.success('Service completed');
      await _fetchDashboard();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to complete service');
      return false;
    }
  }

  Future<bool> requestPart({
    required int serviceId,
    required int sparePartId,
    required int quantity,
    int? taskId,
  }) async {
    try {
      final data = <String, dynamic>{
        'sparePartId':       sparePartId,
        'quantityRequested': quantity,
        if (taskId != null) 'taskId': taskId,
      };
      await _api.post(ApiEndpoints.requestServicePart(serviceId), data: data);
      FerosSnackbar.success('Part requested');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to request part');
      return false;
    }
  }

  // Helper to extract tasks from a service map
  List<Map<String, dynamic>> tasksOf(Map<String, dynamic> service) {
    final raw = service['tasks'];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }
}
