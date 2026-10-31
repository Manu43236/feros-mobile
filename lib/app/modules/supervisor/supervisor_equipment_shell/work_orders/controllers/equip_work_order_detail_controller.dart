import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/exceptions/app_exception.dart';
import '../../../../../../core/utils/view_state.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/services/upload_service.dart';

class EquipWorkOrderDetailController extends GetxController {
  final _api    = Get.find<ApiClient>();
  final _upload = Get.find<UploadService>();

  final state          = ViewState.loading.obs;
  final wo             = Rxn<Map<String, dynamic>>();
  final assignments    = <Map<String, dynamic>>[].obs;
  final logs           = <Map<String, dynamic>>[].obs;

  final sessionLoading   = Rxn<int>(); // assignment id being actioned
  final isAddingLog      = false.obs;
  final uploadingLogId   = Rxn<int>(); // log id whose photo is uploading
  final crew             = <Map<String, dynamic>>[].obs; // active staff for crew pickers
  final presentIds       = <int>{}.obs; // userIds with attendance taken today (PENDING/APPROVED)
  final divisions        = <Map<String, dynamic>>[].obs; // client divisions for the division picker

  late final int woId;

  // Only staff whose attendance is taken today are selectable (matches the backend gate + web).
  List<Map<String, dynamic>> get operators => crew
      .where((u) => (u['role'] as String? ?? '').toUpperCase() == 'OPERATOR' && presentIds.contains(u['id']))
      .toList();
  List<Map<String, dynamic>> get cleaners => crew
      .where((u) => (u['role'] as String? ?? '').toUpperCase() == 'CLEANER' && presentIds.contains(u['id']))
      .toList();

  @override
  void onInit() {
    super.onInit();
    woId = Get.arguments as int;
    fetchDetail();
    _fetchCrew();
    _fetchPresentToday();
  }

  Future<void> _fetchCrew() async {
    try {
      final res = await _api.get(ApiEndpoints.users);
      final all = ((res.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>();
      crew.assignAll(all.where((u) => (u['isActive'] as bool? ?? true)).toList());
    } catch (_) {/* picker just shows empty */}
  }

  Future<void> _fetchPresentToday() async {
    try {
      final date = DateTime.now().toIso8601String().split('T').first;
      final res = await _api.get(ApiEndpoints.attendance, params: {'date': date});
      final list = ((res.data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>();
      presentIds.assignAll(list
          .where((r) {
            final s = (r['approvalStatus'] as String? ?? '').toUpperCase();
            return s == 'PENDING' || s == 'APPROVED';
          })
          .map((r) => r['userId'] as int));
    } catch (_) {/* picker just shows empty */}
  }

  Future<void> fetchDetail() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.equipWorkOrderById(woId));
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      wo.value          = data['workOrder'] as Map<String, dynamic>;
      assignments.value = (data['assignments'] as List? ?? []).cast<Map<String, dynamic>>();
      logs.value        = (data['logs']        as List? ?? []).cast<Map<String, dynamic>>();
      // sort logs descending by date
      logs.sort((a, b) {
        final da = a['logDate'] as String? ?? '';
        final db = b['logDate'] as String? ?? '';
        return db.compareTo(da);
      });
      state.value = ViewState.success;
      _fetchDivisions();
      _fetchShiftToday();
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  // Shift roster for yesterday + today. Two days are needed because an overnight shift
  // (e.g. 10pm–10am) running in the early morning started YESTERDAY, so its crew row is
  // anchored to yesterday's workDate.
  final shiftToday = <Map<String, dynamic>>[].obs;

  static String _dateStr(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _fetchShiftToday() async {
    if ((wo.value?['shiftDuty'] as bool?) != true) return;
    try {
      final today = _dateStr(DateTime.now());
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      final res = await _api.get(ApiEndpoints.equipWoShiftAssignments(woId),
          params: {'from': yesterday, 'to': today});
      shiftToday.assignAll(((res.data as Map<String, dynamic>)['data'] as List? ?? []).cast<Map<String, dynamic>>());
    } catch (_) {/* no shift roster → fall back to picker */}
  }

  /// The shift running right now for this machine + its saved roster row (if any), resolving
  /// overnight shifts to the correct start date (yesterday in the early morning). Null = no
  /// shift covers now. Returns { 'shift': <shift map>, 'row': <roster row?>, 'workDate': <str> }.
  Map<String, dynamic>? currentShift(int assignmentId) {
    final shifts = ((wo.value?['shifts'] as List?) ?? []).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    final nm = now.hour * 60 + now.minute;
    final today = _dateStr(now);
    final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
    int toMin(String t) { final p = t.split(':'); return int.parse(p[0]) * 60 + (p.length > 1 ? int.parse(p[1]) : 0); }
    for (final sh in shifts) {
      final s = toMin(sh['startTime'] as String), e = toMin(sh['endTime'] as String);
      String? workDate;
      if (s < e) {
        if (nm >= s && nm < e) workDate = today;            // day shift, started today
      } else {
        if (nm >= s) workDate = today;                      // overnight, started today
        else if (nm < e) workDate = yesterday;              // overnight, started yesterday
      }
      if (workDate == null) continue;
      Map<String, dynamic>? row;
      for (final r in shiftToday) {
        if (r['assignmentId'] == assignmentId && r['shiftId'] == sh['id'] && r['workDate'] == workDate) {
          row = r;
          break;
        }
      }
      return {'shift': sh, 'row': row, 'workDate': workDate};
    }
    return null;
  }

  /// The current shift's roster row IF it has an operator (own staff or client's own) — used
  /// to resolve the operator when starting a session. Null otherwise.
  Map<String, dynamic>? currentShiftOperator(int assignmentId) {
    final row = currentShift(assignmentId)?['row'] as Map<String, dynamic>?;
    if (row != null && (row['operatorStaffId'] != null || row['clientOperator'] == true)) return row;
    return null;
  }

  Future<void> _fetchDivisions() async {
    final clientId = wo.value?['clientId'];
    if (clientId == null) return;
    try {
      final res = await _api.get(ApiEndpoints.clientDivisions(clientId));
      divisions.assignAll(((res.data as Map<String, dynamic>)['data'] as List? ?? []).cast<Map<String, dynamic>>());
    } catch (_) {/* picker just shows empty */}
  }

  Future<bool> assignDivision(int assignmentId, int? divisionId) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignDivision(woId, assignmentId), data: {'divisionId': divisionId});
      FerosSnackbar.success('Division updated');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to assign division');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // ── Session start ──────────────────────────────────────────────────────────
  Future<bool> startSession(
    int assignmentId, {
    required double startMeter,
    required String operatorType,
    int? operatorStaffId,
    String? hiredOperatorName,
  }) async {
    sessionLoading.value = assignmentId;
    try {
      final body = <String, dynamic>{
        'operatorType': operatorType,
        'startMeter':   startMeter,
        if (operatorStaffId != null)       'operatorStaffId':   operatorStaffId,
        if (hiredOperatorName != null &&
            hiredOperatorName.isNotEmpty)  'hiredOperatorName': hiredOperatorName,
      };
      await _api.post(ApiEndpoints.equipWoStartSession(woId, assignmentId), data: body);
      FerosSnackbar.success('Session started');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error('Failed to start session');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // ── Crew assignment (persistent, mirror of lease driver/cleaner) ─────────────
  Future<bool> assignOperator(int assignmentId,
      {required String operatorType, int? operatorStaffId, String? hiredOperatorName, bool swap = false}) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignOperator(woId, assignmentId), data: {
        'operatorType': operatorType,
        if (operatorStaffId != null) 'operatorStaffId': operatorStaffId,
        if (hiredOperatorName != null && hiredOperatorName.isNotEmpty) 'hiredOperatorName': hiredOperatorName,
        'swap': swap,
      });
      FerosSnackbar.success('Operator assigned');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to assign operator');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  Future<bool> assignCleaner(int assignmentId,
      {int? cleanerStaffId, String? clientCleanerName, bool swap = false}) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignCleaner(woId, assignmentId), data: {
        if (cleanerStaffId != null) 'cleanerStaffId': cleanerStaffId,
        if (clientCleanerName != null && clientCleanerName.isNotEmpty) 'clientCleanerName': clientCleanerName,
        'swap': swap,
      });
      FerosSnackbar.success('Cleaner assigned');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to assign cleaner');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // Unassign operator — null operatorType clears the machine's operator (backend contract).
  Future<bool> removeOperator(int assignmentId) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignOperator(woId, assignmentId),
          data: {'operatorType': null, 'swap': false});
      FerosSnackbar.success('Operator removed');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to remove operator');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // Unassign cleaner — null staff + null client name clears the machine's cleaner.
  Future<bool> removeCleaner(int assignmentId) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignCleaner(woId, assignmentId),
          data: {'cleanerStaffId': null, 'clientCleanerName': null, 'swap': false});
      FerosSnackbar.success('Cleaner removed');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to remove cleaner');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  Future<bool> assignShift(int assignmentId,
      {required int shiftId, required String workDate, int? operatorStaffId, String? clientOperatorName, int? cleanerStaffId, String? clientCleanerName}) async {
    sessionLoading.value = assignmentId;
    try {
      await _api.put(ApiEndpoints.equipWoAssignShift(woId, assignmentId), data: {
        'shiftId': shiftId,
        'workDate': workDate,
        if (operatorStaffId != null) 'operatorStaffId': operatorStaffId,
        if (clientOperatorName != null && clientOperatorName.isNotEmpty) 'clientOperatorName': clientOperatorName,
        if (cleanerStaffId != null) 'cleanerStaffId': cleanerStaffId,
        if (clientCleanerName != null && clientCleanerName.isNotEmpty) 'clientCleanerName': clientCleanerName,
      });
      FerosSnackbar.success('Shift crew assigned');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to assign shift crew');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // Whole-shift clear — removes operator AND cleaner for one shift/day (deletes the row).
  Future<bool> clearShift(int assignmentId, int shiftId, String workDate) async {
    sessionLoading.value = assignmentId;
    try {
      final path =
          '${ApiEndpoints.equipWoAssignShift(woId, assignmentId)}?shiftId=$shiftId&workDate=$workDate';
      await _api.delete(path);
      FerosSnackbar.success('Shift crew cleared');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error(_errMsg(e) ?? 'Failed to clear shift');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  String? _errMsg(Object e) {
    // ApiClient wraps all failures as AppException (ConflictException etc.) carrying the
    // backend message — read that first; fall back to a raw DioException body if present.
    if (e is AppException) return e.message;
    try {
      final d = (e as dynamic).response?.data;
      if (d is Map && d['message'] is String) return d['message'] as String;
    } catch (_) {}
    return null;
  }

  // ── Session stop ───────────────────────────────────────────────────────────
  Future<bool> stopSession(
    int assignmentId, {
    required double endMeter,
    String? notes,
  }) async {
    sessionLoading.value = assignmentId;
    try {
      final body = <String, dynamic>{
        'endMeter': endMeter,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      await _api.put(ApiEndpoints.equipWoStopSession(woId, assignmentId), data: body);
      FerosSnackbar.success('Session stopped');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error('Failed to stop session');
      return false;
    } finally {
      sessionLoading.value = null;
    }
  }

  // ── Add daily log ──────────────────────────────────────────────────────────
  Future<bool> addLog(Map<String, dynamic> body) async {
    isAddingLog.value = true;
    try {
      await _api.post(ApiEndpoints.equipWoLogs(woId), data: body);
      FerosSnackbar.success('Daily log saved');
      await fetchDetail();
      return true;
    } catch (e) {
      FerosSnackbar.error('Failed to save log');
      return false;
    } finally {
      isAddingLog.value = false;
    }
  }

  // ── Upload signed slip photo ───────────────────────────────────────────────
  Future<void> pickAndUploadSlip(int logId) async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (xFile == null) return;
    uploadingLogId.value = logId;
    try {
      final url = await _upload.uploadFileGetPublicUrl(
        File(xFile.path),
        folder: 'tenants/images/signed-slips',
      );
      await _api.put(
        ApiEndpoints.equipWoLogById(woId, logId),
        data: {'signedSlipPhotoUrl': url},
      );
      FerosSnackbar.success('Signed slip uploaded');
      await fetchDetail();
    } catch (_) {
      FerosSnackbar.error('Upload failed');
    } finally {
      uploadingLogId.value = null;
    }
  }
}
