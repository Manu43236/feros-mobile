import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class SupervisorLrDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state       = ViewState.loading.obs;
  final lr          = Rxn<Map<String, dynamic>>();
  final checkposts  = <Map<String, dynamic>>[].obs;
  final charges     = <Map<String, dynamic>>[].obs;
  final chargeTypes = <Map<String, dynamic>>[].obs;

  final isUpdating        = false.obs;
  final isAddingCheckpost = false.obs;
  final isAddingCharge    = false.obs;
  final pdfLoading        = false.obs;
  final proofs            = <Map<String, dynamic>>[].obs;
  final isReviewingId     = Rxn<int>();

  late final int lrId;

  @override
  void onInit() {
    super.onInit();
    lrId = Get.arguments as int;
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.lrById(lrId)),
        _api.get(ApiEndpoints.lrCheckposts(lrId)),
        _api.get(ApiEndpoints.lrCharges(lrId)),
        _api.get(ApiEndpoints.tripProofsByLr(lrId)),
      ]);
      lr.value = (results[0].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      checkposts.assignAll(
          ((results[1].data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      charges.assignAll(
          ((results[2].data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      proofs.assignAll(
          ((results[3].data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[LR Detail] $e');
      state.value = ViewState.error;
    }
  }

  Future<void> reviewProof(int proofId, {String? remarks}) async {
    isReviewingId.value = proofId;
    try {
      final res = await _api.put(
        ApiEndpoints.reviewTripProof(proofId),
        data: {'reviewRemarks': remarks ?? ''},
      );
      final updated = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final idx = proofs.indexWhere((p) => p['id'] == proofId);
      if (idx != -1) proofs[idx] = updated;
      FerosSnackbar.success('Proof reviewed');
    } catch (_) {
      FerosSnackbar.error('Failed to review proof');
    }
    isReviewingId.value = null;
  }

  Future<void> ensureChargeTypesLoaded() async {
    if (chargeTypes.isNotEmpty) return;
    try {
      final res  = await _api.get(ApiEndpoints.chargeTypes);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      chargeTypes.assignAll(list);
    } catch (_) {}
  }

  // ── Status Updates ──────────────────────────────────────────────────────────

  Future<bool> recordLoading(Map<String, dynamic> data) async {
    isUpdating.value = true;
    try {
      final res = await _api.put(ApiEndpoints.lrById(lrId), data: {
        'lrStatus': 'WEIGHT_LOADED',
        ...data,
      });
      lr.value = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      FerosSnackbar.success('Loading recorded');
      isUpdating.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to update');
      isUpdating.value = false;
      return false;
    }
  }

Future<bool> markDelivered(Map<String, dynamic> data) async {
    isUpdating.value = true;
    try {
      final res = await _api.put(ApiEndpoints.lrById(lrId), data: {
        'lrStatus': 'DELIVERED',
        ...data,
      });
      lr.value = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      FerosSnackbar.success('Marked as delivered');
      isUpdating.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to update');
      isUpdating.value = false;
      return false;
    }
  }

  // ── Checkposts ──────────────────────────────────────────────────────────────

  Future<bool> addCheckpost(Map<String, dynamic> data) async {
    isAddingCheckpost.value = true;
    try {
      final res = await _api.post(ApiEndpoints.lrCheckposts(lrId), data: data);
      final newItem = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      checkposts.add(newItem);
      FerosSnackbar.success('Checkpost added');
      isAddingCheckpost.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to add checkpost');
      isAddingCheckpost.value = false;
      return false;
    }
  }

  // ── Charges ─────────────────────────────────────────────────────────────────

  Future<bool> addCharge(Map<String, dynamic> data) async {
    isAddingCharge.value = true;
    try {
      final res = await _api.post(ApiEndpoints.lrCharges(lrId), data: data);
      final newItem = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      charges.add(newItem);
      FerosSnackbar.success('Charge added');
      isAddingCharge.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to add charge');
      isAddingCharge.value = false;
      return false;
    }
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────

  Future<bool> cancelLr() async {
    isUpdating.value = true;
    try {
      final res = await _api.put(ApiEndpoints.lrById(lrId), data: {
        'lrStatus': 'CANCELLED',
      });
      lr.value = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      FerosSnackbar.success('LR cancelled');
      isUpdating.value = false;
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to cancel LR');
      isUpdating.value = false;
      return false;
    }
  }

  // ── PDF ─────────────────────────────────────────────────────────────────────

  Future<void> viewPdf() async {
    if (pdfLoading.value) return;
    pdfLoading.value = true;
    try {
      final lrNumber = lr.value?['lrNumber'] as String? ?? 'LR-$lrId';
      final route    = '${lr.value?['fromCity'] ?? ''} → ${lr.value?['toCity'] ?? ''}';
      final bytes    = await _api.getBytes(ApiEndpoints.lrPdf(lrId));
      final dir      = await getTemporaryDirectory();
      final file     = File('${dir.path}/$lrNumber.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {'file': file, 'title': route, 'subtitle': lrNumber},
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('Failed to load PDF');
    }
    pdfLoading.value = false;
  }
}
