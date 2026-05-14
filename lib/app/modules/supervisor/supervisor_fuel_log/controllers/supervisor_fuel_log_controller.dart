import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class SupervisorFuelLogController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading = true.obs;
  final isAdding  = false.obs;
  final logs      = <Map<String, dynamic>>[].obs;

  final litresCtrl  = TextEditingController();
  final costCtrl    = TextEditingController();
  final odmCtrl     = TextEditingController();
  final stationCtrl = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  @override
  void onClose() {
    litresCtrl.dispose();
    costCtrl.dispose();
    odmCtrl.dispose();
    stationCtrl.dispose();
    super.onClose();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs);
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      logs.value = (raw.cast<Map<String, dynamic>>())
        ..sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
    } catch (_) {
      FerosSnackbar.error('Failed to load fuel logs');
    }
    isLoading.value = false;
  }

  Future<bool> addLog() async {
    final litres = double.tryParse(litresCtrl.text.trim());
    final cost   = double.tryParse(costCtrl.text.trim());
    final odm    = double.tryParse(odmCtrl.text.trim());
    if (litres == null || cost == null) {
      FerosSnackbar.error('Enter litres and cost');
      return false;
    }
    isAdding.value = true;
    try {
      await _api.post(ApiEndpoints.fuelLogs, data: {
        'litresFilled': litres,
        'totalCost': cost,
        if (odm != null) 'odometerReading': odm,
        if (stationCtrl.text.trim().isNotEmpty)
          'fuelStationName': stationCtrl.text.trim(),
        'fillDate': DateTime.now().toIso8601String().split('T')[0],
      });
      FerosSnackbar.success('Fuel log added');
      litresCtrl.clear();
      costCtrl.clear();
      odmCtrl.clear();
      stationCtrl.clear();
      fetch();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to add fuel log');
      return false;
    } finally {
      isAdding.value = false;
    }
  }
}
