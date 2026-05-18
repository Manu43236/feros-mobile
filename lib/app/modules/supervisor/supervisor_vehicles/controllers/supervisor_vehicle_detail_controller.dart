import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorVehicleDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  // ── Vehicle (primary) ────────────────────────────────────────────────────────
  final vehicleState = ViewState.loading.obs;
  final vehicle      = Rxn<Map<String, dynamic>>();

  // ── Per-tab states ────────────────────────────────────────────────────────────
  final servicesState    = ViewState.loading.obs;
  final breakdownsState  = ViewState.loading.obs;
  final fuelState        = ViewState.loading.obs;
  final meterState       = ViewState.loading.obs;

  // ── Data lists ────────────────────────────────────────────────────────────────
  final services      = <Map<String, dynamic>>[].obs;
  final breakdowns    = <Map<String, dynamic>>[].obs;
  final fuelLogs      = <Map<String, dynamic>>[].obs;
  final meterReadings = <Map<String, dynamic>>[].obs;

  // ── Service filter ────────────────────────────────────────────────────────────
  final serviceFilter = 'all'.obs;

  // ── Load guards ───────────────────────────────────────────────────────────────
  bool _servicesLoaded    = false;
  bool _breakdownsLoaded  = false;
  bool _fuelLoaded        = false;
  bool _meterLoaded       = false;

  late final int vehicleId;

  @override
  void onInit() {
    super.onInit();
    vehicleId = Get.arguments as int;
    _fetchVehicle();
  }

  // ── Vehicle ───────────────────────────────────────────────────────────────────
  Future<void> _fetchVehicle() async {
    vehicleState.value = ViewState.loading;
    try {
      final res   = await _api.get(ApiEndpoints.vehicleById(vehicleId));
      vehicle.value =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      vehicleState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] vehicle fetch error: $e');
      vehicleState.value = ViewState.error;
    }
  }

  Future<void> retryVehicle() => _fetchVehicle();

  // ── Services ──────────────────────────────────────────────────────────────────
  void ensureServicesLoaded() {
    if (_servicesLoaded) return;
    _servicesLoaded = true;
    _fetchServices();
  }

  Future<void> retryServices() {
    _servicesLoaded = true;
    return _fetchServices();
  }

  Future<void> _fetchServices() async {
    servicesState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicleServicesByVehicle(vehicleId));
      services.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      servicesState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] services error: $e');
      servicesState.value = ViewState.error;
    }
  }

  List<Map<String, dynamic>> get filteredServices {
    final f = serviceFilter.value;
    if (f == 'all') return services;
    return services.where((s) {
      final status  = s['status']        as String? ?? '';
      final display = s['displayStatus'] as String? ?? status;
      switch (f) {
        case 'open':        return status  == 'OPEN';
        case 'in_progress': return status  == 'IN_PROGRESS';
        case 'due_soon':    return display == 'DUE_SOON';
        case 'overdue':     return display == 'OVERDUE';
        case 'completed':   return display == 'COMPLETED';
        default:            return true;
      }
    }).toList();
  }

  int serviceCount(String f) {
    if (f == 'all') return services.length;
    return services.where((s) {
      final status  = s['status']        as String? ?? '';
      final display = s['displayStatus'] as String? ?? status;
      switch (f) {
        case 'open':        return status  == 'OPEN';
        case 'in_progress': return status  == 'IN_PROGRESS';
        case 'due_soon':    return display == 'DUE_SOON';
        case 'overdue':     return display == 'OVERDUE';
        case 'completed':   return display == 'COMPLETED';
        default:            return true;
      }
    }).length;
  }

  int get openBreakdownCount => breakdowns
      .where((b) =>
          b['status'] != 'RESOLVED' && b['status'] != 'VEHICLE_REPLACED')
      .length;

  // ── Breakdowns ────────────────────────────────────────────────────────────────
  void ensureBreakdownsLoaded() {
    if (_breakdownsLoaded) return;
    _breakdownsLoaded = true;
    _fetchBreakdowns();
  }

  Future<void> retryBreakdowns() {
    _breakdownsLoaded = true;
    return _fetchBreakdowns();
  }

  Future<void> _fetchBreakdowns() async {
    breakdownsState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicleBreakdowns,
          params: {'vehicleId': vehicleId});
      breakdowns.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      breakdownsState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] breakdowns error: $e');
      breakdownsState.value = ViewState.error;
    }
  }

  // ── Fuel CRUD ─────────────────────────────────────────────────────────────────
  final isFuelSaving = false.obs;

  Future<bool> saveFuelLog(Map<String, dynamic> data, {int? editId}) async {
    isFuelSaving.value = true;
    try {
      if (editId != null) {
        await _api.put(ApiEndpoints.fuelLogById(editId), data: data);
      } else {
        await _api.post(ApiEndpoints.fuelLogs, data: data);
      }
      await _fetchFuelLogs();
      isFuelSaving.value = false;
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] save fuel error: $e');
      isFuelSaving.value = false;
      return false;
    }
  }

  Future<bool> deleteFuelLog(int id) async {
    try {
      await _api.delete(ApiEndpoints.fuelLogById(id));
      await _fetchFuelLogs();
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] delete fuel error: $e');
      return false;
    }
  }

  // ── Fuel Logs ─────────────────────────────────────────────────────────────────
  void ensureFuelLoaded() {
    if (_fuelLoaded) return;
    _fuelLoaded = true;
    _fetchFuelLogs();
  }

  Future<void> retryFuel() {
    _fuelLoaded = true;
    return _fetchFuelLogs();
  }

  Future<void> _fetchFuelLogs() async {
    fuelState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.fuelLogs,
          params: {'vehicleId': vehicleId});
      fuelLogs.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      fuelState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] fuel error: $e');
      fuelState.value = ViewState.error;
    }
  }

  // ── Documents (ADMIN / OFFICE_STAFF) ─────────────────────────────────────────
  final docsState  = ViewState.loading.obs;
  final docs       = <Map<String, dynamic>>[].obs;
  bool _docsLoaded = false;

  void ensureDocsLoaded() {
    if (_docsLoaded) return;
    _docsLoaded = true;
    _fetchDocs();
  }

  Future<void> retryDocs() {
    _docsLoaded = true;
    return _fetchDocs();
  }

  Future<void> _fetchDocs() async {
    docsState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicleDocuments(vehicleId));
      docs.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      docsState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] docs error: $e');
      docsState.value = ViewState.error;
    }
  }

  Future<bool> verifyDocument(int docId) async {
    try {
      await _api.put(ApiEndpoints.vehicleDocumentVerify(docId), data: {});
      await _fetchDocs();
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] verify doc error: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(int docId) async {
    try {
      await _api.delete(ApiEndpoints.vehicleDocumentById(docId));
      await _fetchDocs();
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] delete doc error: $e');
      return false;
    }
  }

  // ── Images (ADMIN / OFFICE_STAFF) ────────────────────────────────────────────
  final imagesState  = ViewState.loading.obs;
  final images       = <Map<String, dynamic>>[].obs;
  bool _imagesLoaded = false;

  void ensureImagesLoaded() {
    if (_imagesLoaded) return;
    _imagesLoaded = true;
    _fetchImages();
  }

  Future<void> retryImages() {
    _imagesLoaded = true;
    return _fetchImages();
  }

  Future<void> _fetchImages() async {
    imagesState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.vehicleImages(vehicleId));
      images.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      imagesState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] images error: $e');
      imagesState.value = ViewState.error;
    }
  }

  // ── Toggle Active (ADMIN) ─────────────────────────────────────────────────────
  final isToggling = false.obs;

  Future<bool> toggleActive() async {
    isToggling.value = true;
    try {
      await _api.patch(ApiEndpoints.vehicleToggleActive(vehicleId), data: {});
      await _fetchVehicle();
      isToggling.value = false;
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] toggle active error: $e');
      isToggling.value = false;
      return false;
    }
  }

  Future<void> refreshVehicle() => _fetchVehicle();

  // ── Meter CRUD ────────────────────────────────────────────────────────────────
  final isMeterSaving = false.obs;

  Future<bool> createMeterReading(Map<String, dynamic> data) async {
    isMeterSaving.value = true;
    try {
      await _api.post(ApiEndpoints.meterReadings, data: data);
      await _fetchMeterReadings();
      isMeterSaving.value = false;
      return true;
    } catch (e) {
      debugPrint('[VehicleDetail] create meter error: $e');
      isMeterSaving.value = false;
      return false;
    }
  }

  // ── Meter Readings ────────────────────────────────────────────────────────────
  void ensureMeterLoaded() {
    if (_meterLoaded) return;
    _meterLoaded = true;
    _fetchMeterReadings();
  }

  Future<void> retryMeter() {
    _meterLoaded = true;
    return _fetchMeterReadings();
  }

  Future<void> _fetchMeterReadings() async {
    meterState.value = ViewState.loading;
    try {
      final res = await _api.get(ApiEndpoints.meterReadings,
          params: {'vehicleId': vehicleId});
      meterReadings.assignAll(
          ((res.data as Map<String, dynamic>)['data'] as List)
              .cast<Map<String, dynamic>>());
      meterState.value = ViewState.success;
    } catch (e) {
      debugPrint('[VehicleDetail] meter error: $e');
      meterState.value = ViewState.error;
    }
  }
}
