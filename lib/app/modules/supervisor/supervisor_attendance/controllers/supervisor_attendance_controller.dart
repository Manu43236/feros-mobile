import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state       = ViewState.loading.obs;
  final markLoading = false.obs;
  final bulkLoading = false.obs;

  final records         = <Map<String, dynamic>>[].obs;
  final crew            = <Map<String, dynamic>>[].obs;
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  final leaveTypes      = <Map<String, dynamic>>[].obs;

  static final _dateFmt  = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('dd MMM yyyy, EEE');

  DateTime get _today  => DateTime.now();
  String get dateStr   => _dateFmt.format(_today);
  String get dateLabel => _labelFmt.format(_today);

  // ── Computed ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get crewRecords {
    final crewIds = crew.map((u) => u['id']).toSet();
    return records.where((r) => crewIds.contains(r['userId'])).toList();
  }

  int get present => crewRecords.where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).length;

  int get absent => crewRecords.where((r) =>
      (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('absent')).length;

  int get halfDay => crewRecords.where((r) =>
      (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('half')).length;

  int get unmarked => crew.length - crewRecords.length;

  List<Map<String, dynamic>> get presentCrew => crewRecords.where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).toList();

  List<Map<String, dynamic>> get unmarkedCrew {
    final markedIds = crewRecords.map((r) => r['userId']).toSet();
    return crew.where((u) => !markedIds.contains(u['id'])).toList();
  }

  Map<String, dynamic>? recordForUser(dynamic userId) {
    for (final r in crewRecords) {
      if (r['userId'] == userId) return r;
    }
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      await Future.wait([_fetchAttendance(), _fetchCrew(), _fetchMasters()]);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[SupervisorAttendance] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> _fetchAttendance() async {
    final res = await _api.get(ApiEndpoints.attendance, params: {'date': dateStr});
    final list = ((res.data as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>();
    records.assignAll(list);
  }

  Future<void> _fetchCrew() async {
    final res = await _api.get(ApiEndpoints.users);
    final all = ((res.data as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>();
    crew.assignAll(all.where((u) {
      final role   = (u['role'] as String? ?? '').toUpperCase();
      final active = u['isActive'] as bool? ?? true;
      return active && (role == 'DRIVER' || role == 'CLEANER');
    }).toList());
  }

  Future<void> _fetchMasters() async {
    final results = await Future.wait([
      _api.get(ApiEndpoints.attendanceTypes),
      _api.get(ApiEndpoints.leaveTypes),
    ]);
    attendanceTypes.assignAll(
      ((results[0].data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>(),
    );
    leaveTypes.assignAll(
      ((results[1].data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>(),
    );
  }

  // ── Mark single ───────────────────────────────────────────────────────────────
  Future<bool> markForUser({
    required int userId,
    required int attendanceTypeId,
    int? leaveTypeId,
    String? remarks,
  }) async {
    markLoading.value = true;
    try {
      await _api.post(ApiEndpoints.attendance, data: {
        'userId': userId,
        'attendanceDate': dateStr,
        'attendanceTypeId': attendanceTypeId,
        if (leaveTypeId != null) 'leaveTypeId': leaveTypeId,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });
      await _fetchAttendance();
      return true;
    } catch (e) {
      debugPrint('[SupervisorAttendance] markForUser: $e');
      return false;
    } finally {
      markLoading.value = false;
    }
  }

  // ── Bulk mark all unmarked crew ───────────────────────────────────────────────
  Future<bool> markBulkPresent(int attendanceTypeId) async {
    final unmkd = unmarkedCrew;
    if (unmkd.isEmpty) return true;

    bulkLoading.value = true;
    try {
      await _api.post(ApiEndpoints.attendanceBulk, data: {
        'attendanceDate': dateStr,
        'entries': unmkd
            .map((u) => {'userId': u['id'], 'attendanceTypeId': attendanceTypeId})
            .toList(),
      });
      await _fetchAttendance();
      return true;
    } catch (e) {
      debugPrint('[SupervisorAttendance] markBulkPresent: $e');
      return false;
    } finally {
      bulkLoading.value = false;
    }
  }
}
