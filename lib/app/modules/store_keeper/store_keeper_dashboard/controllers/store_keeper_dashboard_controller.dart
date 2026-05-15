import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class StoreKeeperDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading    = true.obs;
  final stockItems   = <Map<String, dynamic>>[].obs;
  final spareParts   = <Map<String, dynamic>>[].obs;
  final searchQuery  = ''.obs;
  final filterLow    = false.obs;
  final pendingCount = 0.obs;

  List<Map<String, dynamic>> get filteredItems {
    var list = stockItems.toList();
    if (filterLow.value) list = list.where((i) => i['isLowStock'] == true).toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) {
        final name = (i['partName']    as String? ?? '').toLowerCase();
        final num  = (i['partNumber']  as String? ?? '').toLowerCase();
        final cat  = (i['category']    as String? ?? '').toLowerCase();
        return name.contains(q) || num.contains(q) || cat.contains(q);
      }).toList();
    }
    return list;
  }

  int get totalItems    => stockItems.length;
  int get inStockCount  => stockItems.where((i) => (i['quantity'] as num? ?? 0) > 0).length;
  int get lowStockCount => stockItems.where((i) => i['isLowStock'] == true).length;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    await Future.wait([_fetchStock(), _fetchPendingCount(), _fetchSpareParts()]);
    isLoading.value = false;
  }

  Future<void> _fetchStock() async {
    try {
      final res = await _api.get(ApiEndpoints.stock);
      stockItems.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _fetchPendingCount() async {
    try {
      final res = await _api.get(ApiEndpoints.partRequestsPending);
      final list = res.data['data'] as List? ?? [];
      pendingCount.value = list.length;
    } catch (_) {}
  }

  Future<void> _fetchSpareParts() async {
    try {
      final res = await _api.get(ApiEndpoints.spareParts);
      spareParts.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {}
  }

  void onSearch(String q) => searchQuery.value = q;

  void toggleLowStockFilter() => filterLow.value = !filterLow.value;

  Future<bool> submitStockIn({
    required int sparePartId,
    required int quantity,
    double? unitCost,
    String? supplierName,
    String? notes,
  }) async {
    try {
      await _api.post(ApiEndpoints.stockIn, data: {
        'sparePartId': sparePartId,
        'quantity': quantity,
        if (unitCost != null) 'unitCost': unitCost,
        if (supplierName?.isNotEmpty ?? false) 'supplierName': supplierName,
        if (notes?.isNotEmpty ?? false) 'notes': notes,
      });
      await fetchAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(int sparePartId) async {
    try {
      final res = await _api.get('${ApiEndpoints.inventoryTransactions}/part/$sparePartId');
      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
      return [];
    }
  }
}
