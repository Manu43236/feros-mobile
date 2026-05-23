import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../store_keeper_dashboard/controllers/store_keeper_dashboard_controller.dart';

class StoreKeeperRequestsController extends GetxController {
  final _api = Get.find<ApiClient>();

  // ── Spare Parts ──────────────────────────────────────────────────────────────
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

  // ── Tyre Requests ────────────────────────────────────────────────────────────
  final isLoadingTyreRequests = true.obs;
  final tyreRequests          = <Map<String, dynamic>>[].obs;

  int get pendingTyreCount =>
      tyreRequests.where((r) => r['status'] == 'PENDING').length;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
    fetchTyreRequests();
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

  Future<void> fetchTyreRequests() async {
    isLoadingTyreRequests.value = true;
    try {
      final res = await _api.get(ApiEndpoints.tyreRequestsPending);
      tyreRequests.value =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
    } finally {
      isLoadingTyreRequests.value = false;
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

  Future<bool> approveTyreRequest(int id) async {
    try {
      await _api.patch(ApiEndpoints.approveTyreRequest(id));
      await fetchTyreRequests();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectTyreRequest(int id, String reason) async {
    try {
      await _api.patch(
        ApiEndpoints.rejectTyreRequest(id),
        data: {'rejectionReason': reason},
      );
      await fetchTyreRequests();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _syncDashboardCount() {
    try {
      final dash = Get.find<StoreKeeperDashboardController>();
      dash.pendingCount.value = pendingCount;
      dash.fetchPendingCount();
    } catch (_) {}
  }
}
