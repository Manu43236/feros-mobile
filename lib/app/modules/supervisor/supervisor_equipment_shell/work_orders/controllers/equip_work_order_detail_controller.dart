import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
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

  late final int woId;

  @override
  void onInit() {
    super.onInit();
    woId = Get.arguments as int;
    fetchDetail();
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
    } catch (_) {
      state.value = ViewState.error;
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
