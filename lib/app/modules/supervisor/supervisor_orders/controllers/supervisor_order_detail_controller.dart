import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class SupervisorOrderDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final order        = Rxn<Map<String, dynamic>>();
  final lrs          = <Map<String, dynamic>>[].obs;
  final pdfLoadingId  = Rxn<int>();
  final isCreatingLr  = false.obs;

  // ── Vehicle assignment ─────────────────────────────────────────────────────
  final vehicles          = <Map<String, dynamic>>[].obs;
  final isLoadingVehicles = false.obs;
  final isAssigning       = false.obs;
  final unassigningId     = Rxn<int>();

  // ── Staff assignment ───────────────────────────────────────────────────────
  final drivers             = <Map<String, dynamic>>[].obs;
  final cleaners            = <Map<String, dynamic>>[].obs;
  final isLoadingStaff      = false.obs;
  final isAssigningDriver   = false.obs;
  final isAssigningCleaner  = false.obs;
  final isUnassigningDriver = false.obs;
  final isUnassigningCleaner = false.obs;

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int;
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.orderById(orderId)),
        _api.get(ApiEndpoints.lrsByOrder(orderId)),
      ]);

      order.value = (results[0].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

      lrs.value = ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  // ── Fetch available vehicles (called lazily when assign sheet opens) ────────
  Future<void> fetchVehicles() async {
    isLoadingVehicles.value = true;
    vehicles.clear();
    try {
      final res  = await _api.get(ApiEndpoints.vehicles);
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      vehicles.value = data
          .where((v) => v['isActive'] == true && v['isAssigned'] != true)
          .toList();
    } catch (_) {
      FerosSnackbar.error('Failed to load vehicles');
    }
    isLoadingVehicles.value = false;
  }

  // ── Assign vehicle ─────────────────────────────────────────────────────────
  Future<bool> assignVehicle({
    required int    vehicleId,
    required double allocatedWeight,
    String? expectedLoadDate,
    String? expectedDeliveryDate,
    String? remarks,
  }) async {
    isAssigning.value = true;
    try {
      final body = <String, dynamic>{
        'vehicleId':       vehicleId,
        'allocatedWeight': allocatedWeight,
      };
      if (expectedLoadDate != null)     body['expectedLoadDate']     = expectedLoadDate;
      if (expectedDeliveryDate != null) body['expectedDeliveryDate'] = expectedDeliveryDate;
      if (remarks != null)              body['remarks']              = remarks;

      await _api.post(ApiEndpoints.assignVehicle(orderId), data: body);
      FerosSnackbar.success('Vehicle assigned successfully');
      fetchAll();
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isAssigning.value = false;
    }
  }

  // ── Unassign vehicle ───────────────────────────────────────────────────────
  Future<void> unassignVehicle(int allocationId) async {
    unassigningId.value = allocationId;
    try {
      await _api.delete(ApiEndpoints.unassignVehicle(orderId, allocationId));
      FerosSnackbar.success('Vehicle unassigned');
      fetchAll();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    unassigningId.value = null;
  }

  // ── Fetch staff (called lazily when assign staff sheet opens) ─────────────
  Future<void> fetchStaff() async {
    isLoadingStaff.value = true;
    drivers.clear();
    cleaners.clear();
    try {
      final res  = await _api.get(ApiEndpoints.users,
          params: {'hasAttendanceToday': true});
      final data = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final active = data.where(
          (u) => u['isActive'] == true && u['isAssigned'] != true);
      drivers.value  = active.where((u) => u['role'] == 'DRIVER').toList();
      cleaners.value = active.where((u) => u['role'] == 'CLEANER').toList();
    } catch (_) {
      FerosSnackbar.error('Failed to load staff');
    }
    isLoadingStaff.value = false;
  }

  // ── Assign driver to vehicle ───────────────────────────────────────────────
  Future<bool> assignDriver({ required int vehicleId, required int userId }) async {
    isAssigningDriver.value = true;
    try {
      await _api.put(ApiEndpoints.vehicleAssignDriver(vehicleId), data: {'userId': userId});
      FerosSnackbar.success('Driver assigned successfully');
      fetchAll();
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isAssigningDriver.value = false;
    }
  }

  // ── Assign cleaner to vehicle ──────────────────────────────────────────────
  Future<bool> assignCleaner({ required int vehicleId, required int userId }) async {
    isAssigningCleaner.value = true;
    try {
      await _api.put(ApiEndpoints.vehicleAssignCleaner(vehicleId), data: {'userId': userId});
      FerosSnackbar.success('Cleaner assigned successfully');
      fetchAll();
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isAssigningCleaner.value = false;
    }
  }

  // ── Unassign driver from vehicle ───────────────────────────────────────────
  Future<void> unassignDriver(int vehicleId) async {
    isUnassigningDriver.value = true;
    try {
      await _api.delete(ApiEndpoints.vehicleAssignDriver(vehicleId));
      FerosSnackbar.success('Driver unassigned');
      fetchAll();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    isUnassigningDriver.value = false;
  }

  // ── Unassign cleaner from vehicle ──────────────────────────────────────────
  Future<void> unassignCleaner(int vehicleId) async {
    isUnassigningCleaner.value = true;
    try {
      await _api.delete(ApiEndpoints.vehicleAssignCleaner(vehicleId));
      FerosSnackbar.success('Cleaner unassigned');
      fetchAll();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    isUnassigningCleaner.value = false;
  }

  // ── Create LR ──────────────────────────────────────────────────────────────
  Future<bool> createLr(Map<String, dynamic> data) async {
    isCreatingLr.value = true;
    try {
      await _api.post(ApiEndpoints.lrs, data: data);
      FerosSnackbar.success('LR created successfully');
      fetchAll();
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isCreatingLr.value = false;
    }
  }

  // ── Order status ───────────────────────────────────────────────────────────
  final isUpdatingStatus = false.obs;

  Future<bool> updateStatus(String newStatus) async {
    isUpdatingStatus.value = true;
    try {
      final res = await _api.patch(
        ApiEndpoints.orderStatus(orderId),
        queryParameters: {'status': newStatus},
      );
      order.value = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      FerosSnackbar.success('Order status updated');
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  Future<bool> forceDeliver() async {
    isUpdatingStatus.value = true;
    try {
      final res = await _api.patch(ApiEndpoints.orderForceDeliver(orderId));
      order.value = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      FerosSnackbar.success('Order marked as delivered');
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  // ── LR PDF ─────────────────────────────────────────────────────────────────
  Future<void> viewLrPdf(int lrId, String lrNumber, String route) async {
    if (pdfLoadingId.value != null) return;
    pdfLoadingId.value = lrId;
    try {
      final bytes = await _api.getBytes(ApiEndpoints.lrPdf(lrId));
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/$lrNumber.pdf');
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
    pdfLoadingId.value = null;
  }
}
