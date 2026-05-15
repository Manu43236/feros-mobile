import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class StoreKeeperRequestsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = true.obs;
  final requests  = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final res = await _api.get(ApiEndpoints.partRequestsPending);
      requests.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> approveRequest(int servicePartId, int quantityApproved) async {
    try {
      await _api.put(
        ApiEndpoints.approveServicePart(servicePartId),
        data: {'status': 'APPROVED', 'quantityApproved': quantityApproved},
      );
      requests.removeWhere((r) => r['servicePartId'] == servicePartId);
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
      requests.removeWhere((r) => r['servicePartId'] == servicePartId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
