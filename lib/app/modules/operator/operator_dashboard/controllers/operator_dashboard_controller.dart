import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/utils/view_state.dart';

class OperatorDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state           = ViewState.initial.obs;
  final assignment      = Rxn<Map<String, dynamic>>();
  final sessions        = <Map<String, dynamic>>[].obs;
  final totalHmrToday   = Rxn<double>();
  final isAttendanceIn  = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetch();
    fetchAttendanceStatus();
  }

  Future<void> fetch() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.operatorSessionToday);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      assignment.value    = data['assignment'] as Map<String, dynamic>?;
      sessions.value      = (data['todaySessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      totalHmrToday.value = (data['totalHmrToday'] as num?)?.toDouble();
      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  Future<void> fetchAttendanceStatus() async {
    try {
      final res  = await _api.get(ApiEndpoints.attendanceTodayStatus);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      final status = data?['status'] as String?;
      isAttendanceIn.value = status == 'PRESENT';
    } catch (_) {}
  }

  Future<bool> startSession(Map<String, dynamic> body) async {
    try {
      await _api.post(ApiEndpoints.operatorSessionStart, data: body);
      FerosSnackbar.success('Session started');
      fetch();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to start session');
      return false;
    }
  }

  Future<bool> closeSession(int id, Map<String, dynamic> body) async {
    try {
      await _api.put(ApiEndpoints.operatorSessionClose(id), data: body);
      FerosSnackbar.success('Session closed');
      fetch();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to close session');
      return false;
    }
  }

  Future<bool> deleteSession(int id) async {
    try {
      await _api.delete(ApiEndpoints.operatorSessionDelete(id));
      FerosSnackbar.success('Session deleted');
      fetch();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to delete session');
      return false;
    }
  }

  bool get hasOpenSession => sessions.any((s) => s['isOpen'] == true);

  Map<String, dynamic>? get openSession =>
      sessions.where((s) => s['isOpen'] == true).firstOrNull;

  double? get lastKnownHmr {
    final hmr = assignment.value?['lastKnownHmr'];
    return (hmr as num?)?.toDouble();
  }
}
