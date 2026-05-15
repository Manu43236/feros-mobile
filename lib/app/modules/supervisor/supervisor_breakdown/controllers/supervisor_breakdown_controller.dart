import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class SupervisorBreakdownController extends GetxController {
  final _api = Get.find<ApiClient>();

  final reasonCtrl = TextEditingController();
  final notesCtrl  = TextEditingController();

  final breakdownType     = 'MECHANICAL'.obs;
  final breakdownDuration = 'SHORT'.obs;
  final position          = Rxn<Position>();
  final isGettingLocation = false.obs;
  final isSubmitting      = false.obs;

  final vehicles          = <Map<String, dynamic>>[].obs;
  final selectedVehicle   = Rxn<Map<String, dynamic>>();
  final isLoadingVehicles = false.obs;

  static const types     = ['MECHANICAL', 'ELECTRICAL', 'TYRE', 'ACCIDENT', 'OTHER'];
  static const durations = ['SHORT', 'LONG'];

  @override
  void onInit() {
    super.onInit();
    _loadVehicles();
  }

  @override
  void onClose() {
    reasonCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadVehicles() async {
    isLoadingVehicles.value = true;
    try {
      final res  = await _api.get(ApiEndpoints.vehicles);
      final list = ((res.data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();
      vehicles.assignAll(list.where((v) => v['isActive'] == true).toList());
    } catch (_) {
      FerosSnackbar.error('Failed to load vehicles');
    }
    isLoadingVehicles.value = false;
  }

  Future<void> getLocation() async {
    isGettingLocation.value = true;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        FerosSnackbar.error('Location permission denied');
        return;
      }
      position.value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      FerosSnackbar.success('Location captured');
    } catch (_) {
      FerosSnackbar.error('Could not get location');
    }
    isGettingLocation.value = false;
  }

  Future<void> submit() async {
    final vehicle = selectedVehicle.value;
    if (vehicle == null) {
      FerosSnackbar.error('Please select a vehicle');
      return;
    }
    if (reasonCtrl.text.trim().isEmpty) {
      FerosSnackbar.error('Please describe the breakdown reason');
      return;
    }
    isSubmitting.value = true;
    try {
      final pos       = position.value;
      final vehicleId = vehicle['id'] as int;
      await _api.post(ApiEndpoints.vehicleBreakdownById(vehicleId), data: {
        'breakdownType':     breakdownType.value,
        'breakdownDuration': breakdownDuration.value,
        'breakdownDate':     DateTime.now().toIso8601String(),
        'reason':            reasonCtrl.text.trim(),
        if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
        if (pos != null)
          'location': '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
      });
      FerosSnackbar.success('Breakdown reported');
      reasonCtrl.clear();
      notesCtrl.clear();
      position.value        = null;
      selectedVehicle.value = null;
    } catch (_) {
      FerosSnackbar.error('Failed to report breakdown');
    }
    isSubmitting.value = false;
  }
}
