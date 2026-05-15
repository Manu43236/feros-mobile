import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../store_keeper_dashboard/controllers/store_keeper_dashboard_controller.dart';

class StoreKeeperRequestsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading   = true.obs;
  final requests    = <Map<String, dynamic>>[].obs;
  final searchQuery = ''.obs;

  List<Map<String, dynamic>> get filteredRequests {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return requests.toList();
    return requests.where((r) {
      final name = (r['partName']         as String? ?? '').toLowerCase();
      final by   = (r['requestedByName']  as String? ?? '').toLowerCase();
      final veh  = (r['vehicleNumber']    as String? ?? '').toLowerCase();
      return name.contains(q) || by.contains(q) || veh.contains(q);
    }).toList();
  }

  int get pendingCount =>
      requests.where((r) => r['status'] == 'REQUESTED').length;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final res = await _api.get(ApiEndpoints.partRequestsAll);
      requests.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String q) => searchQuery.value = q;

  Future<bool> approveRequest(int servicePartId, int quantityApproved) async {
    try {
      await _api.put(
        ApiEndpoints.approveServicePart(servicePartId),
        data: {'status': 'APPROVED', 'quantityApproved': quantityApproved},
      );
      await fetchRequests();
      _syncDashboardCount();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRequest(int servicePartId, String reason) async {
    try {
      await _api.put(
        ApiEndpoints.approveServicePart(servicePartId),
        data: {'status': 'REJECTED', 'rejectionReason': reason},
      );
      await fetchRequests();
      _syncDashboardCount();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _syncDashboardCount() {
    try {
      Get.find<StoreKeeperDashboardController>().fetchPendingCount();
    } catch (_) {}
  }
}
