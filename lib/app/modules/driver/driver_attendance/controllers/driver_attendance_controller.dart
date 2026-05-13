import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class DriverAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = false.obs;
  final records   = <Map<String, dynamic>>[].obs;
  final month     = Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month));
  final selectedDay = Rxn<int>();

  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final from = DateTime(month.value.year, month.value.month, 1);
      final to   = DateTime(month.value.year, month.value.month + 1, 0);
      final res  = await _api.get(ApiEndpoints.myAttendance, params: {
        'from': _fmt(from),
        'to':   _fmt(to),
      });
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      records.value = raw.cast<Map<String, dynamic>>();
    } catch (_) {
      FerosSnackbar.error('Failed to load attendance');
    }
    isLoading.value = false;
  }

  void prevMonth() {
    month.value    = DateTime(month.value.year, month.value.month - 1);
    selectedDay.value = null;
    fetch();
  }

  void nextMonth() {
    final now = DateTime.now();
    if (month.value.year == now.year && month.value.month == now.month) return;
    month.value    = DateTime(month.value.year, month.value.month + 1);
    selectedDay.value = null;
    fetch();
  }

  void selectDay(int day) {
    selectedDay.value = selectedDay.value == day ? null : day;
  }

  // ── Computed ───────────────────────────────────────────────────────────────
  Map<int, Map<String, dynamic>> get recordsByDay {
    final map = <int, Map<String, dynamic>>{};
    for (final r in records) {
      final d = DateTime.tryParse(r['attendanceDate'] as String? ?? '');
      if (d != null) map[d.day] = r;
    }
    return map;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.value.year == now.year && month.value.month == now.month;
  }

  bool get todayMarked {
    if (!isCurrentMonth) return false;
    final record = recordsByDay[DateTime.now().day];
    if (record == null) return false;
    return (record['approvalStatus'] as String?) != 'REJECTED';
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
