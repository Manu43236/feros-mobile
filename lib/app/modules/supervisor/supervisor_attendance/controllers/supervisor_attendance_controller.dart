import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorAttendanceController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final state        = ViewState.loading.obs;
  final selectedDate = DateTime.now().obs;

  // DRIVER + CLEANER staff list
  final staff           = <Map<String, dynamic>>[].obs;
  // Attendance type options
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  // userId → selected attendanceTypeId (null = not yet selected)
  final selections      = <int, int?>{}.obs;
  // userId → existing attendance record for selectedDate
  final existing        = <int, Map<String, dynamic>>{}.obs;

  final isSubmitting = false.obs;

  // ── Self attendance ───────────────────────────────────────────────────────────
  final selfStatus    = Rxn<Map<String, dynamic>>();
  final selfSelection = Rxn<int>();
  final isMarkingSelf = false.obs;

  // ── Search ────────────────────────────────────────────────────────────────────
  final searchQuery = ''.obs;

  String get supervisorName => _auth.user?.name ?? 'You';

  List<Map<String, dynamic>> get filteredStaff {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return staff;
    return staff
        .where((s) =>
            (s['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  static final _dateFmt  = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('dd MMM yyyy, EEE');

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  String get dateStr   => _dateFmt.format(selectedDate.value);
  String get dateLabel => _labelFmt.format(selectedDate.value);

  Future<void> changeDate(DateTime date) async {
    selectedDate.value = date;
    searchQuery.value  = '';
    await _refreshAttendance();
    if (_isToday) await _fetchSelfStatus();
  }

  bool get _isToday {
    final now = DateTime.now();
    final d   = selectedDate.value;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.users),
        _api.get(ApiEndpoints.attendanceTypes),
        _api.get(ApiEndpoints.attendance, params: {'date': dateStr}),
      ]);

      // Staff: active DRIVER + CLEANER only, sorted by name
      final allUsers = ((results[0].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      staff.assignAll(
        allUsers.where((u) {
          final role     = u['role']     as String? ?? '';
          final isActive = u['isActive'] as bool?   ?? true;
          return isActive && (role == 'DRIVER' || role == 'CLEANER');
        }).toList()
          ..sort((a, b) => ((a['name'] as String?) ?? '')
              .compareTo((b['name'] as String?) ?? '')),
      );

      // Attendance types (active only)
      final types = ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      attendanceTypes.assignAll(
        types.where((t) => t['isActive'] as bool? ?? true).toList(),
      );

      // Existing attendance for selected date
      _parseExisting(
        ((results[2].data as Map<String, dynamic>)['data'] as List)
            .cast<Map<String, dynamic>>(),
      );

      // Self status (only meaningful for today)
      await _fetchSelfStatus();

      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Attendance] fetch error: $e');
      state.value = ViewState.error;
    }
  }

  Future<void> _fetchSelfStatus() async {
    try {
      final res = await _api.get(ApiEndpoints.attendanceTodayStatus);
      selfStatus.value =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    } catch (_) {
      selfStatus.value = null;
    }
  }

  Future<void> markSelfAttendance() async {
    if (selfSelection.value == null) return;
    isMarkingSelf.value = true;
    try {
      final res = await _api.post(ApiEndpoints.attendanceMarkPresent,
          data: {'attendanceTypeId': selfSelection.value});
      selfStatus.value =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      selfSelection.value = null;
      FerosSnackbar.success('Your attendance marked');
    } catch (_) {
      FerosSnackbar.error('Failed to mark your attendance');
    }
    isMarkingSelf.value = false;
  }

  Future<void> _refreshAttendance() async {
    try {
      final res = await _api.get(ApiEndpoints.attendance,
          params: {'date': dateStr});
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      _parseExisting(list);
      // Remove selections for users who are now marked
      final updated = Map<int, int?>.from(selections);
      updated.removeWhere((uid, _) => existing.containsKey(uid));
      selections.value = updated;
    } catch (_) {}
  }

  void _parseExisting(List<Map<String, dynamic>> list) {
    final map = <int, Map<String, dynamic>>{};
    for (final att in list) {
      final raw = att['userId'];
      if (raw == null) continue;
      final uid = raw is int ? raw : int.tryParse(raw.toString());
      if (uid != null) map[uid] = att;
    }
    existing.value = map;
  }

  bool isMarked(int userId)         => existing.containsKey(userId);
  String? markedTypeName(int userId) =>
      existing[userId]?['attendanceTypeName'] as String?;

  void setSelection(int userId, int? typeId) {
    selections[userId] = typeId;
    selections.refresh();
  }

  // Count of selections not yet submitted (exclude already-marked users)
  int get pendingCount => selections.entries
      .where((e) => e.value != null && !isMarked(e.key))
      .length;

  Future<void> submit() async {
    final entries = selections.entries
        .where((e) => e.value != null && !isMarked(e.key))
        .map((e) => {'userId': e.key, 'attendanceTypeId': e.value})
        .toList();

    if (entries.isEmpty) {
      FerosSnackbar.warning('Select attendance type for at least one staff member');
      return;
    }

    isSubmitting.value = true;
    try {
      await _api.post(ApiEndpoints.attendanceBulk, data: {
        'attendanceDate': dateStr,
        'entries': entries,
      });
      FerosSnackbar.success('Attendance marked for ${entries.length} staff');
      // Clear submitted selections then refresh
      final updated = Map<int, int?>.from(selections);
      for (final e in entries) {
        updated.remove(e['userId'] as int);
      }
      selections.value = updated;
      await _refreshAttendance();
    } catch (_) {
      FerosSnackbar.error('Failed to submit attendance');
    }
    isSubmitting.value = false;
  }
}
