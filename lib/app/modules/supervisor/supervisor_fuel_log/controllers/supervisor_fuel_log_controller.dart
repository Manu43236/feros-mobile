import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/popups/feros_snackbar.dart';
import '../../../../../../core/services/upload_service.dart';

class SupervisorFuelLogController extends GetxController {
  final _api    = Get.find<ApiClient>();
  final _upload = Get.find<UploadService>();

  final isLoading          = true.obs;
  final isAdding           = false.obs;
  final isLoadingMore      = false.obs;
  final isUploadingReceipt = false.obs;
  final hasMore            = true.obs;
  final totalCount         = 0.obs;
  final logs               = <Map<String, dynamic>>[].obs;

  int _page = 0;
  static const _pageSize = 20;
  late final ScrollController scrollController;

  // Vehicles
  final vehicles          = <Map<String, dynamic>>[].obs;
  final selectedVehicleId = Rxn<int>();

  double? get tankCapacity => _vehicleField('fuelTankCapacity');
  double? get currentFuel  => _vehicleField('currentFuelLevel');
  double? get currentOdm   => _vehicleField('currentOdometerReading');
  double? get maxFillable  => tankCapacity != null ? tankCapacity! - (currentFuel ?? 0) : null;

  double? _vehicleField(String key) {
    if (selectedVehicleId.value == null) return null;
    final v = vehicles.firstWhereOrNull((v) => v['id'] == selectedVehicleId.value);
    final val = v?[key];
    if (val == null) return null;
    return (val as num).toDouble();
  }

  // Form state
  final selectedDateTime   = Rx<DateTime>(DateTime.now());
  final isFullTank         = false.obs;
  final paymentMode        = 'CASH'.obs;
  final receiptUrl         = ''.obs;
  final editingId          = Rxn<int>();

  final litresCtrl       = TextEditingController();
  final costPerLitreCtrl = TextEditingController();
  final totalCostCtrl    = TextEditingController();
  final odmCtrl          = TextEditingController();
  final stationCtrl      = TextEditingController();
  final cityCtrl         = TextEditingController();
  final notesCtrl        = TextEditingController();
  final searchCtrl       = TextEditingController();

  // Search / filter
  final searchQuery = ''.obs;
  final filterMode  = 'ALL'.obs;

  // Stats computed from loaded logs
  double get totalLitres => logs.fold(0.0, (s, l) => s + ((l['litresFilled'] as num?)?.toDouble() ?? 0));
  double get totalSpent  => logs.fold(0.0, (s, l) => s + ((l['totalCost']    as num?)?.toDouble() ?? 0));
  double? get avgMileage {
    final ml = logs.where((l) => l['mileageKmPerLitre'] != null).toList();
    if (ml.isEmpty) return null;
    return ml.fold(0.0, (s, l) => s + ((l['mileageKmPerLitre'] as num?)?.toDouble() ?? 0)) / ml.length;
  }

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
    cityCtrl.dispose();
    notesCtrl.dispose();
    searchCtrl.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Map<String, dynamic> _buildParams({int page = 0}) {
    final p = <String, dynamic>{'page': page, 'size': _pageSize};
    if (searchQuery.value.isNotEmpty) p['search'] = searchQuery.value;
    if (filterMode.value == 'FULL_TANK') {
      p['fullTank'] = true;
    } else if (filterMode.value != 'ALL') {
      p['paymentMode'] = filterMode.value;
    }
    return p;
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    _page = 0;
    hasMore.value = true;
    logs.clear();
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.fuelLogs, params: _buildParams()),
        _api.get(ApiEndpoints.vehicles),
      ]);
      _applyPage(results[0], clear: true);
      final vRaw = (results[1].data as Map<String, dynamic>)['data'] as List? ?? [];
      vehicles.value = vRaw.cast<Map<String, dynamic>>();
    } catch (_) {
      FerosSnackbar.error('Failed to load data');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    _page = 0;
    hasMore.value = true;
    logs.clear();
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs, params: _buildParams());
      _applyPage(res, clear: true);
    } catch (_) {
      FerosSnackbar.error('Failed to load fuel logs');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs, params: _buildParams(page: _page));
      _applyPage(res);
    } catch (_) {
      FerosSnackbar.error('Failed to load more');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _applyPage(dynamic res, {bool clear = false}) {
    final body = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final raw  = (body['content'] as List? ?? []).cast<Map<String, dynamic>>();
    totalCount.value = body['totalElements'] as int? ?? 0;
    hasMore.value    = !(body['last'] as bool? ?? true);
    if (clear) {
      logs.assignAll(raw);
    } else {
      logs.addAll(raw);
    }
    _page++;
  }

  void onSearchChanged(String q) {
    searchQuery.value = q;
    reload();
  }

  void onFilterChanged(String f) {
    filterMode.value = f;
    reload();
  }

  // ── Edit prep ─────────────────────────────────────────────────────────────────
  void prepareForEdit(Map<String, dynamic> log) {
    editingId.value         = (log['id'] as num?)?.toInt();
    selectedVehicleId.value = (log['vehicleId'] as num?)?.toInt();
    selectedDateTime.value  = log['fillDate'] != null
        ? DateTime.tryParse(log['fillDate'] as String) ?? DateTime.now()
        : DateTime.now();
    litresCtrl.text       = (log['litresFilled']    as num?)?.toString() ?? '';
    costPerLitreCtrl.text = (log['costPerLitre']    as num?)?.toString() ?? '';
    totalCostCtrl.text    = (log['totalCost']       as num?)?.toString() ?? '';
    odmCtrl.text          = (log['odometerReading'] as num?)?.toString() ?? '';
    stationCtrl.text      = log['fuelStationName']  as String? ?? '';
    cityCtrl.text         = log['fuelStationCity']  as String? ?? '';
    notesCtrl.text        = log['notes']            as String? ?? '';
    paymentMode.value     = log['paymentMode']      as String? ?? 'CASH';
    receiptUrl.value      = log['receiptUrl']       as String? ?? '';
    isFullTank.value      = log['isFullTank']       as bool?   ?? false;
  }

  void resetForm() {
    editingId.value         = null;
    selectedVehicleId.value = null;
    isFullTank.value        = false;
    paymentMode.value       = 'CASH';
    receiptUrl.value        = '';
    selectedDateTime.value  = DateTime.now();
    litresCtrl.clear();
    costPerLitreCtrl.clear();
    totalCostCtrl.clear();
    odmCtrl.clear();
    stationCtrl.clear();
    cityCtrl.clear();
    notesCtrl.clear();
  }

  // ── Receipt upload ────────────────────────────────────────────────────────────
  Future<void> pickAndUploadReceipt() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (xFile == null) return;
    isUploadingReceipt.value = true;
    try {
      final url = await _upload.uploadFileGetPublicUrl(
        File(xFile.path),
        folder: 'tenants/images/fuel-receipts',
      );
      receiptUrl.value = url;
      FerosSnackbar.success('Receipt uploaded');
    } catch (_) {
      FerosSnackbar.error('Upload failed');
    } finally {
      isUploadingReceipt.value = false;
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
      return 'Tank has ${(currentFuel ?? 0).toStringAsFixed(0)} L — max fillable is ${max.toStringAsFixed(1)} L';
    }
    return null;
  }

  Future<bool> saveLog() async {
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
      final payload = <String, dynamic>{
        'vehicleId':    vId,
        'litresFilled': litres,
        'totalCost':    totalCost,
        if (costPerL != null)                   'costPerLitre':    costPerL,
        if (odm != null)                        'odometerReading': odm,
        if (stationCtrl.text.trim().isNotEmpty) 'fuelStationName': stationCtrl.text.trim(),
        if (cityCtrl.text.trim().isNotEmpty)    'fuelStationCity': cityCtrl.text.trim(),
        if (notesCtrl.text.trim().isNotEmpty)   'notes':           notesCtrl.text.trim(),
        if (receiptUrl.value.isNotEmpty)        'receiptUrl':      receiptUrl.value,
        'isFullTank':  isFullTank.value,
        'paymentMode': paymentMode.value,
        'fillDate':    selectedDateTime.value.toIso8601String().substring(0, 19),
      };

      final id = editingId.value;
      if (id != null) {
        await _api.put(ApiEndpoints.fuelLogById(id), data: payload);
        FerosSnackbar.success('Fuel log updated');
      } else {
        await _api.post(ApiEndpoints.fuelLogs, data: payload);
        FerosSnackbar.success('Fuel log added');
      }
      resetForm();
      reload();
      return true;
    } catch (_) {
      FerosSnackbar.error(editingId.value != null ? 'Failed to update' : 'Failed to add');
      return false;
    } finally {
      isAdding.value = false;
    }
  }

  Future<bool> deleteLog(int id) async {
    try {
      await _api.delete(ApiEndpoints.fuelLogById(id));
      logs.removeWhere((l) => l['id'] == id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      FerosSnackbar.success('Fuel log deleted');
      return true;
    } catch (_) {
      FerosSnackbar.error('Failed to delete');
      return false;
    }
  }
}
