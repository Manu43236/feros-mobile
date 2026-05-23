import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/widgets/odometer_sheet.dart';
import '../../../../../core/widgets/delivery_sheet.dart';
import '../models/lr_model.dart';

class DriverTripDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  late final LrModel lr;

  final lrStatus           = ''.obs;
  final loadedWeight       = Rxn<double>();
  final deliveredWeight    = Rxn<double>();
  final startOdometer      = Rxn<double>();
  final endOdometer        = Rxn<double>();
  final isUpdating         = false.obs;
  final isPdfLoading       = false.obs;
  final hasActiveBreakdown  = false.obs;
  final isCheckingBreakdown = false.obs;

  @override
  void onInit() {
    super.onInit();
    lr                    = Get.arguments as LrModel;
    lrStatus.value        = lr.lrStatus;
    loadedWeight.value    = lr.loadedWeight;
    deliveredWeight.value = lr.deliveredWeight;
    startOdometer.value   = lr.startOdometer;
    endOdometer.value     = lr.endOdometer;
    if (lr.lrStatus == 'IN_TRANSIT') checkBreakdown();
  }

  Future<void> checkBreakdown() async {
    final aId = lr.allocationId;
    if (aId == null) return;
    isCheckingBreakdown.value = true;
    try {
      final res = await _api.get(
          ApiEndpoints.orderBreakdown(lr.orderId, aId));
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data != null) {
        final status = data['status'] as String? ?? '';
        hasActiveBreakdown.value = status == 'REPORTED';
      } else {
        hasActiveBreakdown.value = false;
      }
    } catch (_) {
      // 404 = no breakdown on record → allow buttons
      hasActiveBreakdown.value = false;
    }
    isCheckingBreakdown.value = false;
  }

  void onBreakdownReported() => checkBreakdown();

  Future<void> refresh() async {
    try {
      final res = await _api.get(ApiEndpoints.lrById(lr.id));
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final updated = LrModel.fromJson(data);
      lrStatus.value        = updated.lrStatus;
      loadedWeight.value    = updated.loadedWeight;
      deliveredWeight.value = updated.deliveredWeight;
      startOdometer.value   = updated.startOdometer;
      endOdometer.value     = updated.endOdometer;
    } catch (_) {}
    if (lrStatus.value == 'IN_TRANSIT') await checkBreakdown();
  }

  // ── Start Trip ─────────────────────────────────────────────────────────────
  // Sheet is shown in the view; result passed here for the API call.
  Future<void> startTrip(OdometerResult result) async {
    isUpdating.value = true;
    try {
      await _api.put(ApiEndpoints.lrById(lr.id), data: {
        'lrStatus':      'IN_TRANSIT',
        'startOdometer': result.odometer,
        if (result.photoUrl != null) 'startOdometerPhotoUrl': result.photoUrl,
      });
      lrStatus.value      = 'IN_TRANSIT';
      startOdometer.value = result.odometer;
      FerosSnackbar.success('msg_trip_started'.tr);
    } catch (e) {
      FerosSnackbar.error(e.toString().contains('odometer')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'err_failed_start_trip'.tr);
    }
    isUpdating.value = false;
  }

  // ── Mark Delivered ─────────────────────────────────────────────────────────
  Future<void> markDelivered(OdometerResult odmResult, DeliveryResult deliveryResult) async {
    isUpdating.value = true;
    try {
      await _api.put(ApiEndpoints.lrById(lr.id), data: {
        'lrStatus':        'DELIVERED',
        'deliveredWeight': deliveryResult.weight,
        'deliveredAt':     DateTime.now().toIso8601String(),
        'endOdometer':     odmResult.odometer,
        if (odmResult.photoUrl != null) 'endOdometerPhotoUrl': odmResult.photoUrl,
      });
      lrStatus.value        = 'DELIVERED';
      deliveredWeight.value = deliveryResult.weight;
      endOdometer.value     = odmResult.odometer;
      FerosSnackbar.success('msg_delivery_confirmed'.tr);
    } catch (e) {
      FerosSnackbar.error(e.toString().contains('odometer')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'err_failed_delivery'.tr);
    }
    isUpdating.value = false;
  }

  // ── View PDF ───────────────────────────────────────────────────────────────
  Future<void> viewPdf() async {
    if (isPdfLoading.value) return;
    isPdfLoading.value = true;
    try {
      final bytes = await _api.getBytes(ApiEndpoints.lrPdf(lr.id));
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/${lr.lrNumber}.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {
          'file': file,
          'title': '${lr.fromCity} → ${lr.toCity}',
          'subtitle': lr.lrNumber,
        },
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('err_failed_pdf'.tr);
    }
    isPdfLoading.value = false;
  }
}
