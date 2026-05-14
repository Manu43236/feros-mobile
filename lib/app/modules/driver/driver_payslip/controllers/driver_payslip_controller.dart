import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class DriverPayslipController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = true.obs;
  final payslips  = <Map<String, dynamic>>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final res = await _api.get('${ApiEndpoints.payroll}/my');
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      payslips.value = (raw.cast<Map<String, dynamic>>())
        ..sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
    } catch (_) {
      FerosSnackbar.error('Failed to load payslips');
    }
    isLoading.value = false;
  }
}
