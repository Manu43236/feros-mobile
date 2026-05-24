import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/upload_service.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorMyAttendanceController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state           = ViewState.loading.obs;
  final records         = <Map<String, dynamic>>[].obs;
  final attendanceTypes = <Map<String, dynamic>>[].obs;
  final leaveTypes      = <Map<String, dynamic>>[].obs;
  final markLoading     = false.obs;

  // Stats derived from records
  int get present => records.where((r) {
    final t = (r['attendanceTypeName'] as String? ?? '').toLowerCase();
    return t.contains('present') && !t.contains('half');
  }).length;
  int get absent  => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('absent')).length;
  int get half    => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('half')).length;
  int get leave   => records.where((r) => (r['attendanceTypeName'] as String? ?? '').toLowerCase().contains('leave')).length;
  int get pending => records.where((r) => r['approvalStatus'] == 'PENDING').length;

  Map<String, dynamic>? get todayRecord {
    final today = _dateStr(DateTime.now());
    try {
      return records.firstWhere((r) => r['attendanceDate'] == today);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      await Future.wait([fetchRecords(), _fetchMasters()]);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[MyAttendance] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> fetchRecords() async {
    final now  = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to   = DateTime(now.year, now.month + 1, 0); // last day of month
    final res  = await _api.get(
      ApiEndpoints.myAttendance,
      params: {
        'from': _dateStr(from),
        'to':   _dateStr(to),
      },
    );
    final list = ((res.data as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>();
    records.assignAll(list);
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

  /// Returns the "Present" attendance type ID from the fetched master list.
  int? get _presentTypeId {
    try {
      final t = attendanceTypes.firstWhere((t) {
        final n = (t['name'] as String? ?? '').toLowerCase();
        return n.contains('present') && !n.contains('half');
      });
      return t['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> markPresent({File? selfieFile, String? remarks}) async {
    final typeId = _presentTypeId;
    if (typeId == null) {
      debugPrint('[MyAttendance] No present type found');
      return false;
    }
    markLoading.value = true;
    try {
      String? selfieUrl;
      if (selfieFile != null) {
        selfieUrl = await Get.find<UploadService>()
            .uploadFile(selfieFile, folder: 'attendance');
      }
      await _api.post(ApiEndpoints.myAttendance, data: {
        'attendanceTypeId': typeId,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        if (selfieUrl != null) 'selfieUrl': selfieUrl,
      });
      await fetchRecords();
      return true;
    } catch (e) {
      debugPrint('[MyAttendance] markPresent: $e');
      return false;
    } finally {
      markLoading.value = false;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
