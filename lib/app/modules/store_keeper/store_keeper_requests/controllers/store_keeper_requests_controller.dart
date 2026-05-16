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

  // ── Tire Requests ────────────────────────────────────────────────────────────
  final isLoadingTireRequests = true.obs;
  final tireRequests          = <Map<String, dynamic>>[].obs;
  final isLoadingAvailTires   = false.obs;
  final availableTires        = <Map<String, dynamic>>[].obs;

  int get pendingTireCount =>
      tireRequests.where((r) => r['status'] == 'PENDING').length;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
    fetchTireRequests();
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

  Future<void> fetchTireRequests() async {
    isLoadingTireRequests.value = true;
    try {
      final res = await _api.get(ApiEndpoints.tireRequestsPending);
      tireRequests.value =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
    } finally {
      isLoadingTireRequests.value = false;
    }
  }

  Future<void> fetchAvailableTires() async {
    isLoadingAvailTires.value = true;
    try {
      final res = await _api.get(ApiEndpoints.tiresAvailable);
      availableTires.value =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {}
    isLoadingAvailTires.value = false;
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

  Future<bool> approveTireRequest(int id, int tireId, {double? fittedAtKm}) async {
    try {
      await _api.patch(
        ApiEndpoints.approveTireRequest(id),
        data: {
          'tireId': tireId,
          if (fittedAtKm != null) 'fittedAtKm': fittedAtKm,
        },
      );
      await fetchTireRequests();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectTireRequest(int id, String reason) async {
    try {
      await _api.patch(
        ApiEndpoints.rejectTireRequest(id),
        data: {'rejectionReason': reason},
      );
      await fetchTireRequests();
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
