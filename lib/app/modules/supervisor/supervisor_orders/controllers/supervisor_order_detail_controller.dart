import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  // ── Breakdowns ────────────────────────────────────────────────────────────
  final breakdowns            = <int, Map<String, dynamic>>{}.obs;
  final isReportingBreakdown  = false.obs;
  final isResolvingBreakdown  = false.obs;
  final isCancellingBreakdown = false.obs;
  final isReplacingVehicle    = false.obs;

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

      // Fetch active breakdowns for IN_TRANSIT/BREAKDOWN allocations
      final allocs = (order.value?['vehicleAllocations'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      await Future.wait(allocs
          .where((a) {
            final s = a['allocationStatus'] as String? ?? '';
            return s == 'IN_TRANSIT' || s == 'BREAKDOWN';
          })
          .map((a) => fetchBreakdown(a['id'] as int)));
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  Future<void> fetchBreakdown(int allocationId) async {
    try {
      final res = await _api.get(ApiEndpoints.orderBreakdown(orderId, allocationId));
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data != null) breakdowns[allocationId] = data as Map<String, dynamic>;
    } catch (_) {
      // 404 = no active breakdown — ignore
    }
  }

  Future<bool> reportBreakdown(int allocationId, Map<String, dynamic> data) async {
    isReportingBreakdown.value = true;
    try {
      await _api.post(ApiEndpoints.orderBreakdown(orderId, allocationId), data: data);
      FerosSnackbar.success('Breakdown reported');
      await fetchBreakdown(allocationId);
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isReportingBreakdown.value = false;
    }
  }

  Future<void> resolveBreakdown(int allocationId, int breakdownId) async {
    isResolvingBreakdown.value = true;
    try {
      await _api.post(ApiEndpoints.resolveBreakdown(orderId, breakdownId));
      FerosSnackbar.success('Breakdown resolved — trip continues');
      breakdowns.remove(allocationId);
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    isResolvingBreakdown.value = false;
  }

  Future<void> cancelBreakdown(int allocationId, int breakdownId) async {
    isCancellingBreakdown.value = true;
    try {
      await _api.delete(ApiEndpoints.cancelBreakdown(orderId, breakdownId));
      FerosSnackbar.success('Breakdown report cancelled');
      breakdowns.remove(allocationId);
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    isCancellingBreakdown.value = false;
  }

  Future<bool> replaceVehicle(int breakdownId, Map<String, dynamic> data) async {
    isReplacingVehicle.value = true;
    try {
      await _api.post(ApiEndpoints.replaceVehicle(orderId, breakdownId), data: data);
      FerosSnackbar.success('Replacement vehicle assigned');
      await fetchAll();
      return true;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return false;
    } finally {
      isReplacingVehicle.value = false;
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
  Future<int?> assignVehicle({
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

      final res = await _api.post(ApiEndpoints.assignVehicle(orderId), data: body);
      FerosSnackbar.success('Vehicle assigned successfully');
      fetchAll();
      return ((res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>)['id'] as int?;
    } catch (e) {
      FerosSnackbar.error(e.toString());
      return null;
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

  // ── Assign driver to order allocation ─────────────────────────────────────
  Future<bool> assignDriver({ required int allocationId, required int userId }) async {
    isAssigningDriver.value = true;
    try {
      await _api.post(ApiEndpoints.assignStaff(orderId), data: {
        'vehicleAllocationId': allocationId,
        'userId': userId,
        'slotRole': 'DRIVER',
      });
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

  // ── Assign cleaner to order allocation ────────────────────────────────────
  Future<bool> assignCleaner({ required int allocationId, required int userId }) async {
    isAssigningCleaner.value = true;
    try {
      await _api.post(ApiEndpoints.assignStaff(orderId), data: {
        'vehicleAllocationId': allocationId,
        'userId': userId,
        'slotRole': 'CLEANER',
      });
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

  // ── Unassign driver (order-level staffAllocation) ─────────────────────────
  Future<void> unassignDriver(int staffAllocationId) async {
    isUnassigningDriver.value = true;
    try {
      await _api.delete(ApiEndpoints.unassignStaff(orderId, staffAllocationId));
      FerosSnackbar.success('Driver unassigned');
      fetchAll();
    } catch (e) {
      FerosSnackbar.error(e.toString());
    }
    isUnassigningDriver.value = false;
  }

  // ── Unassign cleaner (order-level staffAllocation) ────────────────────────
  Future<void> unassignCleaner(int staffAllocationId) async {
    isUnassigningCleaner.value = true;
    try {
      await _api.delete(ApiEndpoints.unassignStaff(orderId, staffAllocationId));
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

  // ── Order PDF (share) ──────────────────────────────────────────────────────
  final isShareingPdf = false.obs;

  Future<void> shareOrderPdf() async {
    if (isShareingPdf.value) return;
    final o = order.value;
    if (o == null) return;
    final orderNumber = o['orderNumber'] as String? ?? 'ORDER';
    isShareingPdf.value = true;
    try {
      final bytes = await _api.getBytes(ApiEndpoints.orderPdf(orderId));
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$orderNumber.pdf');
      await file.writeAsBytes(bytes);
      final xFile = XFile(file.path, mimeType: 'application/pdf');
      await SharePlus.instance.share(
        ShareParams(files: [xFile], text: 'Order $orderNumber'),
      );
    } catch (_) {
      FerosSnackbar.error('Failed to generate PDF');
    }
    isShareingPdf.value = false;
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
