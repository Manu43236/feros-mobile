import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final dailyState   = ViewState.loading.obs;
  final pendingState = ViewState.loading.obs;
  final rejectedState= ViewState.loading.obs;

  final selectedDate    = DateTime.now().obs;
  final records         = <Map<String, dynamic>>[].obs; // marked records for date
  final allStaff        = <Map<String, dynamic>>[].obs; // all users
  final pendingList     = <Map<String, dynamic>>[].obs;
  final rejectedList    = <Map<String, dynamic>>[].obs;
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  final leaveTypes      = <Map<String, dynamic>>[].obs;

  final pendingCount  = 0.obs;
  final rejectedCount = 0.obs;

  // Date filters for pending / rejected (null = no filter)
  final pendingFrom  = Rx<DateTime?>(null);
  final pendingTo    = Rx<DateTime?>(null);
  final rejectedFrom = Rx<DateTime?>(null);
  final rejectedTo   = Rx<DateTime?>(null);

  static const staffRoles = [
    'DRIVER', 'CLEANER', 'SUPERVISOR',
    'OFFICE_STAFF', 'SERVICE_MANAGER', 'STORE_KEEPER'
  ];

  @override
  void onInit() {
    super.onInit();
    _loadMasters();
    fetchAll();
  }

  Future<void> _loadMasters() async {
    try {
      final r1 = await _api.get(ApiEndpoints.attendanceTypes);
      attendanceTypes.value = ((r1.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Attendance] types: $e');
    }
    try {
      final r2 = await _api.get(ApiEndpoints.leaveTypes);
      leaveTypes.value = ((r2.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Attendance] leaveTypes: $e');
    }
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchByDate(),
      fetchStaff(),
      fetchPending(),
      fetchRejected(),
    ]);
  }

  Future<void> fetchStaff() async {
    try {
      final res = await _api.get(ApiEndpoints.users);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      allStaff.value = data
          .where((u) => staffRoles.contains(u['role'] as String?))
          .toList();
    } catch (e) {
      debugPrint('[Attendance] staff: $e');
      // Non-admin role can't fetch users — silently ignore
    }
  }

  Future<void> fetchByDate([DateTime? date]) async {
    if (date != null) selectedDate.value = date;
    dailyState.value = ViewState.loading;
    try {
      final d = selectedDate.value;
      final dateStr = _fmt(d);
      final res = await _api.get(
        ApiEndpoints.attendance,
        params: {'date': dateStr},
      );
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // LIFO: sort by id descending
      list.sort((a, b) =>
          ((b['id'] as num?)?.toInt() ?? 0)
              .compareTo((a['id'] as num?)?.toInt() ?? 0));
      records.value = list;
      dailyState.value = ViewState.success;
    } catch (e) {
      debugPrint('[Attendance] daily: $e');
      dailyState.value = ViewState.error;
    }
  }

  Future<void> fetchPending() async {
    pendingState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.attendancePending);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // LIFO: sort by id descending
      list.sort((a, b) =>
          ((b['id'] as num?)?.toInt() ?? 0)
              .compareTo((a['id'] as num?)?.toInt() ?? 0));
      pendingList.value  = list;
      pendingCount.value = list.length;
      pendingState.value = ViewState.success;
    } catch (e) {
      debugPrint('[Attendance] pending: $e');
      pendingState.value = ViewState.error;
    }
  }

  Future<void> fetchRejected() async {
    rejectedState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.attendanceRejected);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // LIFO: sort by id descending
      list.sort((a, b) =>
          ((b['id'] as num?)?.toInt() ?? 0)
              .compareTo((a['id'] as num?)?.toInt() ?? 0));
      rejectedList.value  = list;
      rejectedCount.value = list.length;
      rejectedState.value = ViewState.success;
    } catch (e) {
      debugPrint('[Attendance] rejected: $e');
      rejectedState.value = ViewState.error;
    }
  }

  // Client-side filtered views
  List<Map<String, dynamic>> get filteredPending =>
      _filterByDate(pendingList, pendingFrom.value, pendingTo.value);

  List<Map<String, dynamic>> get filteredRejected =>
      _filterByDate(rejectedList, rejectedFrom.value, rejectedTo.value);

  List<Map<String, dynamic>> _filterByDate(
      List<Map<String, dynamic>> list, DateTime? from, DateTime? to) {
    if (from == null && to == null) return list;
    return list.where((r) {
      final dateStr = r['attendanceDate'] as String?;
      if (dateStr == null) return true;
      final d = DateTime.tryParse(dateStr);
      if (d == null) return true;
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();
  }

  void setPendingFrom(DateTime? d)  { pendingFrom.value  = d; }
  void setPendingTo(DateTime? d)    { pendingTo.value    = d; }
  void setRejectedFrom(DateTime? d) { rejectedFrom.value = d; }
  void setRejectedTo(DateTime? d)   { rejectedTo.value   = d; }
  void clearPendingFilter()  { pendingFrom.value  = pendingTo.value  = null; }
  void clearRejectedFilter() { rejectedFrom.value = rejectedTo.value = null; }

  // Mark single attendance
  Future<void> markAttendance(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.attendance, data: body);
    await fetchByDate();
    await fetchPending();
  }

  // Update existing record
  Future<void> updateAttendance(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.attendanceById(id), data: body);
    await fetchByDate();
    await fetchPending();
  }

  // Bulk mark
  Future<void> bulkMark(List<Map<String, dynamic>> entries) async {
    await _api.post(ApiEndpoints.attendanceBulk, data: {
      'attendanceDate': _fmt(selectedDate.value),
      'entries': entries,
    });
    await fetchByDate();
  }

  Future<void> approve(int id) async {
    await _api.put(ApiEndpoints.approveAttendance(id), data: {});
    await fetchPending();
    await fetchRejected();
    await fetchByDate();
  }

  Future<void> reject(int id) async {
    await _api.put(ApiEndpoints.rejectAttendance(id), data: {});
    await fetchPending();
    await fetchRejected();
    await fetchByDate();
  }

  void shiftDay(int delta) {
    final d = selectedDate.value.add(Duration(days: delta));
    if (!d.isAfter(DateTime.now())) fetchByDate(d);
  }

  void goToday() => fetchByDate(DateTime.now());

  // Build merged list: marked records + unmarked staff rows
  List<Map<String, dynamic>> get mergedRows {
    final markedIds = records.map((r) => (r['userId'] as num?)?.toInt()).toSet();
    final unmarked = allStaff
        .where((u) => !markedIds.contains((u['id'] as num?)?.toInt()))
        .map((u) => {
              '_type': 'unmarked',
              'userId': u['id'],
              'userName': u['name'],
              'roleName': u['role'],
            })
        .toList();
    return [
      ...records.map((r) => {...r, '_type': 'marked'}),
      ...unmarked,
    ];
  }

  // Summary counts
  Map<String, int> get stats {
    int present = 0, absent = 0, half = 0, leave = 0;
    for (final r in records) {
      final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
      if (t.contains('present')) present++;
      else if (t.contains('absent')) absent++;
      else if (t.contains('half')) half++;
      else if (t.contains('leave')) leave++;
    }
    final unmarked = allStaff.length - records.length;
    return {
      'total':    allStaff.length,
      'present':  present,
      'absent':   absent,
      'half':     half,
      'leave':    leave,
      'unmarked': unmarked < 0 ? 0 : unmarked,
    };
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
