import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/services/upload_service.dart';

class SupervisorMeterReadingController extends GetxController {
  final _api    = Get.find<ApiClient>();
  final _upload = Get.find<UploadService>();

  final isLoading        = true.obs;
  final isSaving         = false.obs;
  final isUploadingPhoto = false.obs;
  final readings         = <Map<String, dynamic>>[].obs;
  final vehicles         = <Map<String, dynamic>>[].obs;
  final filterType       = 'ALL'.obs;

  final _allReadings = <Map<String, dynamic>>[];

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.meterReadings),
        _api.get(ApiEndpoints.vehicles),
      ]);
      _storeReadings(results[0]);
      final vRaw = (results[1].data as Map<String, dynamic>)['data'] as List? ?? [];
      vehicles.value = vRaw.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[MeterReading] $e');
      FerosSnackbar.error('Failed to load meter readings');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    try {
      final res = await _api.get(ApiEndpoints.meterReadings);
      _storeReadings(res);
    } catch (_) {
      FerosSnackbar.error('Failed to load readings');
    }
  }

  void _storeReadings(dynamic res) {
    final data = (res.data as Map<String, dynamic>)['data'];
    if (data is List) {
      _allReadings
        ..clear()
        ..addAll(data.cast<Map<String, dynamic>>());
    } else if (data is Map) {
      _allReadings
        ..clear()
        ..addAll((data['content'] as List? ?? []).cast<Map<String, dynamic>>());
    }
    _applyFilter();
  }

  void _applyFilter() {
    final type = filterType.value;
    readings.value = type == 'ALL'
        ? List.of(_allReadings)
        : _allReadings.where((r) => r['readingType'] == type).toList();
  }

  void onFilterChanged(String type) {
    filterType.value = type;
    _applyFilter();
  }

  Future<bool> addReading({
    required int vehicleId,
    required double readingKm,
    required String readingType,
    File? photoFile,
    String? notes,
  }) async {
    isSaving.value = true;
    try {
      String? photoUrl;
      if (photoFile != null) {
        isUploadingPhoto.value = true;
        photoUrl = await _upload.uploadFileGetPublicUrl(
          photoFile,
          folder: 'tenants/images/vehicles/$vehicleId/meter-readings',
        );
        isUploadingPhoto.value = false;
      }

      await _api.post(ApiEndpoints.meterReadings, data: {
        'vehicleId':   vehicleId,
        'readingKm':   readingKm,
        'readingType': readingType,
        if (photoUrl != null) 'photoUrl': photoUrl, // ignore: use_null_aware_elements
        if (notes != null && notes.isNotEmpty) 'notes':    notes,
        'recordedAt': DateTime.now().toIso8601String().substring(0, 19),
      });

      FerosSnackbar.success('Reading recorded');
      reload();
      return true;
    } catch (e) {
      debugPrint('[MeterReading] addReading: $e');
      isUploadingPhoto.value = false;
      FerosSnackbar.error('Failed to save reading');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteReading(int id) async {
    try {
      await _api.delete(ApiEndpoints.meterReadingById(id));
      _allReadings.removeWhere((r) => r['id'] == id);
      _applyFilter();
      FerosSnackbar.success('Reading deleted');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to delete');
      return false;
    }
  }
}
