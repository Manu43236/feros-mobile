import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/utils/view_state.dart';

class EquipAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state       = ViewState.loading.obs;
  final markLoading = false.obs;
  final bulkLoading = false.obs;

  final records         = <Map<String, dynamic>>[].obs;
  final crew            = <Map<String, dynamic>>[].obs;
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  final leaveTypes      = <Map<String, dynamic>>[].obs;
  final watchlistedIds  = <int>{}.obs;

  // Which staff roles this supervisor manages. Lease access → drivers +
  // cleaners; equipment access → operators. Drives the attendance tabs.
  late final bool canAccessEquipment;
  late final bool canAccessLeases;
  bool get bothEnabled => canAccessEquipment && canAccessLeases;

  static final _dateFmt  = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('dd MMM yyyy, EEE');

  DateTime get _today  => DateTime.now();
  String get dateStr   => _dateFmt.format(_today);
  String get dateLabel => _labelFmt.format(_today);

  // ── Global stats (whole crew) — used by the home tab summary ─────────────────
  List<Map<String, dynamic>> get crewRecords {
    final ids = crew.map((u) => u['id']).toSet();
    return records.where((r) => ids.contains(r['userId'])).toList();
  }

  int get present => crewRecords.where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).length;

  int get absent => crewRecords.where((r) =>
      (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('absent')).length;

  int get unmarked => crew.length - crewRecords.length;

  // ── Role subsets ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> crewForRoles(List<String> roles) => crew
      .where((u) => roles.contains((u['role'] as String? ?? '').toUpperCase()))
      .toList();

  bool isWatchlisted(dynamic id) {
    final uid = id is int ? id : int.tryParse(id.toString()) ?? -1;
    return watchlistedIds.contains(uid);
  }

  Map<String, dynamic>? recordForUser(dynamic userId) {
    for (final r in records) {
      if (r['userId'] == userId) return r;
    }
    return null;
  }

  // ── Scoped stats (over a given crew subset, e.g. one tab) ────────────────────
  List<Map<String, dynamic>> _markedIn(List<Map<String, dynamic>> subset) {
    final ids = subset.map((u) => u['id']).toSet();
    return records.where((r) => ids.contains(r['userId'])).toList();
  }

  int presentIn(List<Map<String, dynamic>> subset) => _markedIn(subset).where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).length;

  int absentIn(List<Map<String, dynamic>> subset) => _markedIn(subset).where((r) =>
      (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('absent')).length;

  int unmarkedIn(List<Map<String, dynamic>> subset) =>
      subset.length - _markedIn(subset).length;

  List<Map<String, dynamic>> unmarkedCrewIn(List<Map<String, dynamic>> subset) {
    final markedIds = _markedIn(subset).map((r) => r['userId']).toSet();
    return subset.where((u) => !markedIds.contains(u['id'])).toList();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthService>().user;
    canAccessEquipment = user?.canAccessEquipment ?? false;
    canAccessLeases    = user?.canAccessLeases    ?? false;
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      await Future.wait([
        _fetchAttendance(),
        _fetchCrew(),
        _fetchMasters(),
        if (canAccessLeases) _fetchWatchlistIds(),
      ]);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[EquipAttendance] $e');
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
      if (!active) return false;
      if (role == 'OPERATOR')                    return canAccessEquipment;
      if (role == 'DRIVER' || role == 'CLEANER') return canAccessLeases;
      return false;
    }).toList());
  }

  Future<void> _fetchWatchlistIds() async {
    try {
      final res = await _api.get(ApiEndpoints.watchlistStaffIds);
      final raw = ((res.data as Map<String, dynamic>)['data'] as List);
      watchlistedIds.assignAll(
          raw.map((e) => e is int ? e : (e as num).toInt()).toSet());
    } catch (e) {
      debugPrint('[EquipAttendance] watchlist fetch error: $e');
    }
  }

  Future<void> _fetchMasters() async {
    final results = await Future.wait([
      _api.get(ApiEndpoints.attendanceTypes),
      _api.get(ApiEndpoints.leaveTypes),
    ]);
    attendanceTypes.assignAll(
      ((results[0].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>(),
    );
    leaveTypes.assignAll(
      ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>(),
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
      debugPrint('[EquipAttendance] markForUser: $e');
      return false;
    } finally {
      markLoading.value = false;
    }
  }

  // ── Bulk mark all unmarked in a crew subset ────────────────────────────────────
  Future<bool> markBulkPresent(
      int attendanceTypeId, List<Map<String, dynamic>> subset) async {
    final unmkd = unmarkedCrewIn(subset);
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
      debugPrint('[EquipAttendance] markBulkPresent: $e');
      return false;
    } finally {
      bulkLoading.value = false;
    }
  }
}
