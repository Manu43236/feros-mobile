import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';

class SupervisorFuelLogController extends GetxController {
  final _api = Get.find<ApiClient>();

  final isLoading     = true.obs;
  final isAdding      = false.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;
  final totalCount    = 0.obs;
  final logs          = <Map<String, dynamic>>[].obs;

  int _page = 0;
  static const _pageSize = 20;
  late final ScrollController scrollController;

  // Vehicles
  final vehicles          = <Map<String, dynamic>>[].obs;
  final selectedVehicleId = Rxn<int>();

  // Derived from selected vehicle
  double? get tankCapacity  => _vehicleField('fuelTankCapacity');
  double? get currentFuel   => _vehicleField('currentFuelLevel');
  double? get currentOdm    => _vehicleField('currentOdometerReading');
  double? get maxFillable   => (tankCapacity != null) ? tankCapacity! - (currentFuel ?? 0) : null;

  double? _vehicleField(String key) {
    if (selectedVehicleId.value == null) return null;
    final v = vehicles.firstWhereOrNull((v) => v['id'] == selectedVehicleId.value);
    final val = v?[key];
    if (val == null) return null;
    return (val as num).toDouble();
  }

  // Form state
  final selectedDateTime  = Rx<DateTime>(DateTime.now());
  final isFullTank        = false.obs;

  final litresCtrl        = TextEditingController();
  final costPerLitreCtrl  = TextEditingController();
  final totalCostCtrl     = TextEditingController();
  final odmCtrl           = TextEditingController();
  final stationCtrl       = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    scrollController = ScrollController()..addListener(_onScroll);
    fetchAll();
  }

  @override
  void onClose() {
    scrollController.dispose();
    litresCtrl.dispose();
    costPerLitreCtrl.dispose();
    totalCostCtrl.dispose();
    odmCtrl.dispose();
    stationCtrl.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    _page = 0;
    hasMore.value = true;
    logs.clear();
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.fuelLogs, params: {'page': 0, 'size': _pageSize}),
        _api.get(ApiEndpoints.vehicles),
      ]);
      final body = (results[0].data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final raw = (body['content'] as List? ?? []).cast<Map<String, dynamic>>();
      totalCount.value = body['totalElements'] as int? ?? 0;
      hasMore.value = !(body['last'] as bool? ?? true);
      logs.assignAll(raw);
      _page = 1;

      final vRaw = (results[1].data as Map<String, dynamic>)['data'] as List? ?? [];
      vehicles.value = vRaw.cast<Map<String, dynamic>>();
    } catch (_) {
      FerosSnackbar.error('Failed to load data');
    }
    isLoading.value = false;
  }

  Future<void> fetch() async {
    _page = 0;
    hasMore.value = true;
    logs.clear();
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs, params: {'page': 0, 'size': _pageSize});
      final body = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final raw = (body['content'] as List? ?? []).cast<Map<String, dynamic>>();
      totalCount.value = body['totalElements'] as int? ?? 0;
      hasMore.value = !(body['last'] as bool? ?? true);
      logs.assignAll(raw);
      _page = 1;
    } catch (_) {
      FerosSnackbar.error('Failed to load fuel logs');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs, params: {'page': _page, 'size': _pageSize});
      final body = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final raw = (body['content'] as List? ?? []).cast<Map<String, dynamic>>();
      hasMore.value = !(body['last'] as bool? ?? true);
      logs.addAll(raw);
      _page++;
    } catch (_) {
      FerosSnackbar.error('Failed to load more');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onVehicleSelected(int? vehicleId) {
    selectedVehicleId.value = vehicleId;
    final odm = currentOdm;
    if (odm != null) odmCtrl.text = odm.toStringAsFixed(0);
    isFullTank.value = false;
    litresCtrl.clear();
    totalCostCtrl.clear();
  }

  void onFullTankChanged(bool checked) {
    isFullTank.value = checked;
    if (checked) {
      final max = maxFillable;
      if (max != null && max > 0) {
        litresCtrl.text = max.toStringAsFixed(2);
        _recalcTotal();
      }
    }
  }

  void recalcTotal() => _recalcTotal();

  void _recalcTotal() {
    final l = double.tryParse(litresCtrl.text.trim());
    final c = double.tryParse(costPerLitreCtrl.text.trim());
    if (l != null && c != null) totalCostCtrl.text = (l * c).toStringAsFixed(2);
  }

  String? validateLitres() {
    final l = double.tryParse(litresCtrl.text.trim());
    if (l == null || l <= 0) return 'Enter valid litres';
    final cap = tankCapacity;
    if (cap != null && l > cap) return 'Exceeds tank capacity (${cap.toStringAsFixed(0)} L)';
    final max = maxFillable;
    if (max != null && l > max) {
      final cur = (currentFuel ?? 0).toStringAsFixed(0);
      return 'Tank has $cur L — max fillable is ${max.toStringAsFixed(1)} L';
    }
    return null;
  }

  Future<bool> addLog() async {
    final vId = selectedVehicleId.value;
    if (vId == null) { FerosSnackbar.error('Select a vehicle'); return false; }

    final litresErr = validateLitres();
    if (litresErr != null) { FerosSnackbar.error(litresErr); return false; }

    final litres    = double.parse(litresCtrl.text.trim());
    final costPerL  = double.tryParse(costPerLitreCtrl.text.trim());
    final totalCost = double.tryParse(totalCostCtrl.text.trim()) ??
        (costPerL != null ? litres * costPerL : null);
    final odm       = double.tryParse(odmCtrl.text.trim());

    if (totalCost == null) { FerosSnackbar.error('Enter cost per litre or total cost'); return false; }

    isAdding.value = true;
    try {
      await _api.post(ApiEndpoints.fuelLogs, data: {
        'vehicleId':    vId,
        'litresFilled': litres,
        'totalCost':    totalCost,
        if (costPerL != null) 'costPerLitre': costPerL,
        if (odm != null) 'odometerReading': odm,
        if (stationCtrl.text.trim().isNotEmpty) 'fuelStationName': stationCtrl.text.trim(),
        'isFullTank': isFullTank.value,
        'fillDate':   selectedDateTime.value.toIso8601String().substring(0, 19),
      });
      FerosSnackbar.success('Fuel log added');
      _resetForm();
      fetch();
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to add fuel log');
      return false;
    } finally {
      isAdding.value = false;
    }
  }

  void _resetForm() {
    selectedVehicleId.value = null;
    isFullTank.value = false;
    selectedDateTime.value = DateTime.now();
    litresCtrl.clear();
    costPerLitreCtrl.clear();
    totalCostCtrl.clear();
    odmCtrl.clear();
    stationCtrl.clear();
  }
}
