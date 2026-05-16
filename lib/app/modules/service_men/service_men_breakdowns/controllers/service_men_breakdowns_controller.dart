import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class ServiceMenBreakdownsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading  = true.obs;
  final breakdowns = <Map<String, dynamic>>[].obs;
  final filter     = 'ALL'.obs;

  List<Map<String, dynamic>> get filtered {
    if (filter.value == 'ALL') return breakdowns;
    if (filter.value == 'OPEN') {
      return breakdowns
          .where((b) =>
              b['status'] != 'RESOLVED' && b['status'] != 'VEHICLE_REPLACED')
          .toList();
    }
    return breakdowns.where((b) => b['status'] == filter.value).toList();
  }

  int get openCount => breakdowns
      .where((b) =>
          b['status'] != 'RESOLVED' && b['status'] != 'VEHICLE_REPLACED')
      .length;

  @override
  void onInit() {
    super.onInit();
    fetchBreakdowns();
  }

  Future<void> fetchBreakdowns() async {
    isLoading.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.vehicleBreakdowns);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      breakdowns.assignAll(list);
    } catch (_) {
      FerosSnackbar.error('Failed to load breakdowns');
    }
    isLoading.value = false;
  }

  Future<bool> resolveBreakdown(int vehicleId, int breakdownId) async {
    try {
      await _api.post(
          ApiEndpoints.resolveVehicleBreakdown(vehicleId, breakdownId));
      await fetchBreakdowns();
      FerosSnackbar.success('Breakdown resolved');
      return true;
    } catch (e) {
      final msg = _extractMessage(e);
      FerosSnackbar.error(msg ?? 'Failed to resolve breakdown');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createServiceFromBreakdown({
    required int vehicleId,
    required int breakdownId,
    required String serviceType,
    required String serviceDate,
    String? notes,
  }) async {
    try {
      final res = await _api.post(ApiEndpoints.vehicleServices, data: {
        'vehicleId':    vehicleId,
        'triggeredBy':  'BREAKDOWN',
        'breakdownId':  breakdownId,
        'serviceType':  serviceType,
        'serviceDate':  serviceDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'tasks': <Map<String, dynamic>>[],
      });
      // Refresh breakdowns list so the card flips to IN_REPAIR
      await fetchBreakdowns();
      return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } catch (e) {
      final msg = _extractMessage(e);
      FerosSnackbar.error(msg ?? 'Failed to create service');
      return null;
    }
  }

  Future<bool> reportBreakdown({
    required int vehicleId,
    required String breakdownType,
    required String breakdownDuration,
    required String reason,
    String? location,
    String? notes,
  }) async {
    try {
      await _api.post(ApiEndpoints.vehicleBreakdownById(vehicleId), data: {
        'breakdownType':     breakdownType,
        'breakdownDuration': breakdownDuration,
        'breakdownDate':     DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
        'reason':            reason,
        if (location != null && location.isNotEmpty) 'location': location,
        if (notes    != null && notes.isNotEmpty)    'notes':    notes,
      });
      await fetchBreakdowns();
      FerosSnackbar.success('Breakdown reported');
      return true;
    } catch (e) {
      final msg = _extractMessage(e);
      FerosSnackbar.error(msg ?? 'Failed to report breakdown');
      return false;
    }
  }

  String? _extractMessage(dynamic e) {
    try {
      return (e as dynamic)?.response?.data?['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
