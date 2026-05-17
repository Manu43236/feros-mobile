import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeInventoryController extends GetxController {
  final _api = Get.find<ApiClient>();

  // ── States ────────────────────────────────────────────────────────────────
  final stockState       = ViewState.loading.obs;
  final partsState       = ViewState.loading.obs;
  final requestsState    = ViewState.loading.obs;
  final tireReqState     = ViewState.loading.obs;

  // ── Data ──────────────────────────────────────────────────────────────────
  final stockItems    = <Map<String, dynamic>>[].obs;
  final spareParts    = <Map<String, dynamic>>[].obs;
  final partRequests  = <Map<String, dynamic>>[].obs;
  final tireRequests  = <Map<String, dynamic>>[].obs;
  final availableTires = <Map<String, dynamic>>[].obs;

  // ── Filters ───────────────────────────────────────────────────────────────
  final stockSearch   = ''.obs;
  final stockLowOnly  = false.obs;
  final partsSearch   = ''.obs;

  // ── Computed ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredStock {
    var list = stockItems.toList();
    if (stockLowOnly.value) list = list.where((i) => i['isLowStock'] == true).toList();
    final q = stockSearch.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((i) {
      final name = (i['partName']   as String? ?? '').toLowerCase();
      final cat  = (i['category']   as String? ?? '').toLowerCase();
      final num  = (i['partNumber'] as String? ?? '').toLowerCase();
      return name.contains(q) || cat.contains(q) || num.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredParts {
    final q = partsSearch.value.trim().toLowerCase();
    if (q.isEmpty) return spareParts.toList();
    return spareParts.where((p) {
      final name = (p['name']       as String? ?? '').toLowerCase();
      final cat  = (p['category']   as String? ?? '').toLowerCase();
      final num  = (p['partNumber'] as String? ?? '').toLowerCase();
      return name.contains(q) || cat.contains(q) || num.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get pendingPartRequests =>
      partRequests.where((r) => r['status'] == 'REQUESTED').toList();

  int get pendingPartCount  => pendingPartRequests.length;
  int get pendingTireCount  => tireRequests.length;

  int get lowStockCount => stockItems.where((i) => i['isLowStock'] == true).length;
  int get inStockCount  => stockItems.where((i) => (i['quantity'] as num? ?? 0) > 0).length;

  int get activeParts     => spareParts.where((p) => p['isActive'] == true).length;
  int get categoryCount   => spareParts
      .map((p) => p['category'] as String?)
      .where((c) => c != null && c.isNotEmpty)
      .toSet()
      .length;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchStock(),
      fetchParts(),
      fetchPartRequests(),
      fetchTireRequests(),
    ]);
  }

  Future<void> fetchStock() async {
    stockState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.stock);
      stockItems.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      stockState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInventory] stock: $e');
      stockState.value = ViewState.error;
    }
  }

  Future<void> fetchParts() async {
    partsState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.spareParts);
      spareParts.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      partsState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInventory] parts: $e');
      partsState.value = ViewState.error;
    }
  }

  Future<void> fetchPartRequests() async {
    requestsState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.partRequestsAll);
      partRequests.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      requestsState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInventory] partRequests: $e');
      requestsState.value = ViewState.error;
    }
  }

  Future<void> fetchTireRequests() async {
    tireReqState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.tireRequestsPending);
      tireRequests.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      tireReqState.value = ViewState.success;
    } catch (e) {
      debugPrint('[OfficeInventory] tireRequests: $e');
      tireReqState.value = ViewState.error;
    }
  }

  Future<void> fetchAvailableTires() async {
    try {
      final res = await _api.get(ApiEndpoints.tiresAvailable);
      availableTires.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[OfficeInventory] availableTires: $e');
    }
  }

  // ── Stock In ──────────────────────────────────────────────────────────────
  Future<void> stockIn(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.stockIn, data: body);
    await fetchStock();
  }

  // ── Spare Parts CRUD ──────────────────────────────────────────────────────
  Future<void> createPart(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.spareParts, data: body);
    await fetchParts();
    await fetchStock();
  }

  Future<void> editPart(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.sparePartById(id), data: body);
    await fetchParts();
  }

  // ── Part Request Approve / Reject ─────────────────────────────────────────
  Future<void> approvePartRequest(int id, int qtyApproved) async {
    await _api.put(ApiEndpoints.approveServicePart(id), data: {
      'status': 'APPROVED',
      'quantityApproved': qtyApproved,
    });
    await fetchPartRequests();
    await fetchStock();
  }

  Future<void> rejectPartRequest(int id, String reason) async {
    await _api.put(ApiEndpoints.approveServicePart(id), data: {
      'status': 'REJECTED',
      'rejectionReason': reason,
    });
    await fetchPartRequests();
  }

  // ── Tire Request Approve / Reject ─────────────────────────────────────────
  Future<void> approveTireRequest(int id, Map<String, dynamic> body) async {
    await _api.patch(ApiEndpoints.approveTireRequest(id), data: body);
    await fetchTireRequests();
  }

  Future<void> rejectTireRequest(int id, String reason) async {
    await _api.patch(ApiEndpoints.rejectTireRequest(id),
        data: {'rejectionReason': reason});
    await fetchTireRequests();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void setStockSearch(String q)  => stockSearch.value = q;
  void setPartsSearch(String q)  => partsSearch.value = q;
  void toggleLowStock()          => stockLowOnly.value = !stockLowOnly.value;
}
