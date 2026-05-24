import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final selectedDate = DateTime.now().obs;
  final records      = <Map<String, dynamic>>[].obs;

  static final _dateFmt  = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('dd MMM yyyy, EEE');

  String get dateStr   => _dateFmt.format(selectedDate.value);
  String get dateLabel => _labelFmt.format(selectedDate.value);

  // Stats
  int get present => records.where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).length;
  int get absent  => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('absent')).length;
  int get half    => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('half')).length;
  int get leave   => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('leave')).length;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.attendance, params: {'date': dateStr});
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      records.assignAll(list);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[SupervisorAttendance] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> changeDate(DateTime date) async {
    selectedDate.value = date;
    await fetchAll();
  }

  void shiftDay(int delta) {
    final d = selectedDate.value.add(Duration(days: delta));
    if (!d.isAfter(DateTime.now())) changeDate(d);
  }
}
