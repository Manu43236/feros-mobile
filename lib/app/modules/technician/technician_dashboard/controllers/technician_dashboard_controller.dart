import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class TechnicianDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading  = true.obs;
  final isActing   = false.obs;

  final tasks      = <Map<String, dynamic>>[].obs;
  final spareParts = <Map<String, dynamic>>[].obs;

  int get assignedCount    => tasks.where((t) => t['status'] == 'ASSIGNED').length;
  int get inProgressCount  => tasks.where((t) => t['status'] == 'IN_PROGRESS').length;
  int get closedCount      => tasks.where((t) => t['status'] == 'MECHANIC_CLOSED').length;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
    fetchSpareParts();
  }

  Future<void> fetchSpareParts() async {
    try {
      final res = await _api.get(ApiEndpoints.spareParts);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      spareParts.assignAll(list);
    } catch (_) {
      // non-critical — parts list just won't show
    }
  }

  Future<void> fetchTasks() async {
    isLoading.value = true;
    try {
      final res = await _api.get(ApiEndpoints.technicianTasks);
      final serviceGroups = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();

      // Flatten: each service group has a nested tasks list; merge asset info into each task
      final flattened = <Map<String, dynamic>>[];
      for (final svc in serviceGroups) {
        final assetType  = svc['assetType'] as String? ?? 'VEHICLE';  // E5 KAN-29
        final assetName  = svc['assetName'] as String?
            ?? svc['vehicleRegistrationNumber'] as String? ?? '';
        final serviceId  = svc['serviceId'];
        final tasksList  = (svc['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final task in tasksList) {
          flattened.add({
            ...task,
            'assetType':      assetType,
            'assetName':      assetName,
            'vehicleRegNumber': assetName,  // backward-compat alias
            'serviceId':      serviceId,
          });
        }
      }
      tasks.assignAll(flattened);
    } catch (_) {
      FerosSnackbar.error('Failed to load tasks');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> startTask(int taskId) async {
    isActing.value = true;
    try {
      await _api.put(ApiEndpoints.technicianStartTask(taskId));
      FerosSnackbar.success('Task started');
      await fetchTasks();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to start task');
      return false;
    } finally {
      isActing.value = false;
    }
  }

  Future<bool> closeTask(int taskId) async {
    isActing.value = true;
    try {
      await _api.put(ApiEndpoints.technicianCloseTask(taskId));
      FerosSnackbar.success('Task closed — awaiting SM review');
      await fetchTasks();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to close task');
      return false;
    } finally {
      isActing.value = false;
    }
  }

  Future<bool> requestPart({
    required int taskId,
    required int sparePartId,
    required int quantity,
  }) async {
    try {
      await _api.post(
        ApiEndpoints.technicianTaskPartRequest(taskId),
        data: {'sparePartId': sparePartId, 'quantityRequested': quantity},
      );
      FerosSnackbar.success('Part requested');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to request part');
      return false;
    }
  }
}
