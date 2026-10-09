import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/exceptions/app_exception.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class VehicleLeasesController extends GetxController {
  final _api = Get.find<ApiClient>();

  // ── List state ───────────────────────────────────────────────────────────────
  final isLoading     = true.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;
  final leases        = <Map<String, dynamic>>[].obs;
  final statusFilter  = 'ACTIVE'.obs;

  int _page = 0;
  static const _size = 20;

  // ── Detail state ─────────────────────────────────────────────────────────────
  final isLoadingDetail = false.obs;
  final lease           = Rxn<Map<String, dynamic>>();
  final vehicles        = <Map<String, dynamic>>[].obs;
  final sessions        = <Map<String, dynamic>>[].obs;
  final divisions       = <Map<String, dynamic>>[].obs;
  final drivers         = <Map<String, dynamic>>[].obs;
  final cleaners        = <Map<String, dynamic>>[].obs;

  // ── Session action state ─────────────────────────────────────────────────────
  final isActioning = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchLeases();
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  Map<String, dynamic> _listParams({int page = 0}) => {
        'page': page,
        'size': _size,
        if (statusFilter.value != 'ALL') 'status': statusFilter.value,
      };

  Future<void> fetchLeases() async {
    isLoading.value = true;
    _page = 0;
    hasMore.value = true;
    leases.clear();
    try {
      final res = await _api.get(ApiEndpoints.vehicleLeases, params: _listParams());
      _applyPage(res, clear: true);
    } catch (_) {
      FerosSnackbar.error('Failed to load leases');
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final res = await _api.get(ApiEndpoints.vehicleLeases, params: _listParams(page: _page));
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
    hasMore.value = !(body['last'] as bool? ?? true);
    if (clear) {
      leases.assignAll(raw);
    } else {
      leases.addAll(raw);
    }
    _page++;
  }

  void onStatusChanged(String s) {
    statusFilter.value = s;
    fetchLeases();
  }

  // ── Detail ────────────────────────────────────────────────────────────────────
  Future<void> fetchDetail(int id) async {
    isLoadingDetail.value = true;
    lease.value = null;
    vehicles.clear();
    sessions.clear();
    divisions.clear();
    drivers.clear();
    cleaners.clear();
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.vehicleLeaseById(id)),
        _api.get(ApiEndpoints.vehicleLeaseVehicles(id)),
        _api.get(ApiEndpoints.vehicleLeaseSessions(id)),
      ]);
      lease.value = (results[0].data as Map)['data'] as Map<String, dynamic>;
      vehicles.assignAll(
        ((results[1].data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      sessions.assignAll(
        ((results[2].data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      final clientId = lease.value?['clientId'];
      final results2 = await Future.wait([
        if (clientId != null) _api.get(ApiEndpoints.clientDivisions(clientId)),
        _api.get(ApiEndpoints.users, params: {'hasAttendanceToday': true}),
      ]);
      if (clientId != null) {
        divisions.assignAll(
          ((results2[0].data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
        );
      }
      final allStaff = ((results2.last.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Available-only: hide staff already on a lease (hard conflict). Order/normal-assigned staff
      // stay visible with their "On order" marker so Swap still works.
      bool onLease(Map<String, dynamic> s) =>
          (s['isAssigned'] as bool? ?? false) && s['assignmentType'] == 'LEASE';
      drivers.assignAll(allStaff.where((s) =>
          (s['role'] as String? ?? '') == 'DRIVER' && (s['isActive'] as bool? ?? false) && !onLease(s)).toList());
      cleaners.assignAll(allStaff.where((s) =>
          (s['role'] as String? ?? '') == 'CLEANER' && (s['isActive'] as bool? ?? false) && !onLease(s)).toList());
    } catch (_) {
      FerosSnackbar.error('Failed to load lease details');
    }
    isLoadingDetail.value = false;
  }

  Future<void> assignDriver(int leaseId, int assignmentId, int? driverStaffId,
      {bool swap = false}) async {
    try {
      await _api.put(
        ApiEndpoints.vehicleLeaseAssignDriver(leaseId, assignmentId),
        data: {'driverStaffId': driverStaffId, 'swap': swap},
      );
    } on ConflictException catch (e) {
      // SWAPPABLE_CONFLICT → driver is on a normal/order vehicle (not mid-trip): offer to swap.
      if (e.code == 'SWAPPABLE_CONFLICT') {
        final confirmed = await Get.dialog<bool>(AlertDialog(
          title: const Text('Swap driver?'),
          content: Text('${e.message}\n\nUnassign them and move to this lease?'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            TextButton(onPressed: () => Get.back(result: true), child: const Text('Swap')),
          ],
        )) ?? false;
        if (confirmed) {
          await assignDriver(leaseId, assignmentId, driverStaffId, swap: true);
        }
      } else {
        FerosSnackbar.error(e.message); // HARD_BLOCK (on lease / in progress) — no swap
      }
    } on AppException catch (e) {
      FerosSnackbar.error(e.message);
    } catch (_) {
      FerosSnackbar.error('Failed to assign driver');
    }
  }

  Future<void> assignCleaner(int leaseId, int assignmentId, int? cleanerStaffId,
      {bool swap = false}) async {
    try {
      await _api.put(
        ApiEndpoints.vehicleLeaseAssignCleaner(leaseId, assignmentId),
        data: {'cleanerStaffId': cleanerStaffId, 'swap': swap},
      );
    } on ConflictException catch (e) {
      // SWAPPABLE_CONFLICT → cleaner is on a normal/order vehicle (not mid-trip): offer to swap.
      if (e.code == 'SWAPPABLE_CONFLICT') {
        final confirmed = await Get.dialog<bool>(AlertDialog(
          title: const Text('Swap cleaner?'),
          content: Text('${e.message}\n\nUnassign them and move to this lease?'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            TextButton(onPressed: () => Get.back(result: true), child: const Text('Swap')),
          ],
        )) ?? false;
        if (confirmed) {
          await assignCleaner(leaseId, assignmentId, cleanerStaffId, swap: true);
        }
      } else {
        FerosSnackbar.error(e.message); // HARD_BLOCK (on lease / in progress) — no swap
      }
    } on AppException catch (e) {
      FerosSnackbar.error(e.message);
    } catch (_) {
      FerosSnackbar.error('Failed to assign cleaner');
    }
  }

  Future<void> assignDivision(int leaseId, int assignmentId, int? divisionId) async {
    try {
      await _api.put(
        ApiEndpoints.vehicleLeaseAssignDivision(leaseId, assignmentId),
        data: {'divisionId': divisionId},
      );
    } catch (_) {
      FerosSnackbar.error('Failed to assign division');
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? activeSessionFor(int assignmentId) =>
      sessions.firstWhereOrNull(
        (s) => s['assignmentId'] == assignmentId && s['isActive'] == true,
      );

  Future<void> startSession(
    int leaseId,
    int assignmentId, {
    int? driverStaffId,
    int? odometerStart,
    String? notes,
  }) async {
    isActioning.value = true;
    try {
      // No startTime — backend stamps its own now(), avoids device clock skew.
      final payload = <String, dynamic>{
        if (driverStaffId != null) 'driverStaffId': driverStaffId,
        if (odometerStart != null) 'odometerStart': odometerStart,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      await _api.post(ApiEndpoints.vehicleLeaseStartSession(leaseId, assignmentId), data: payload);
      FerosSnackbar.success('Session started');
      await _refreshSessions(leaseId);
    } catch (e) {
      FerosSnackbar.error('Failed to start session');
    } finally {
      isActioning.value = false;
    }
  }

  Future<void> endSession(
    int leaseId,
    int assignmentId, {
    int? odometerEnd,
    String? notes,
  }) async {
    isActioning.value = true;
    try {
      // No endTime — backend stamps its own now(), avoids device clock skew.
      final payload = <String, dynamic>{
        if (odometerEnd != null) 'odometerEnd': odometerEnd,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      await _api.put(ApiEndpoints.vehicleLeaseEndSession(leaseId, assignmentId), data: payload);
      FerosSnackbar.success('Session ended');
      await _refreshSessions(leaseId);
    } catch (e) {
      FerosSnackbar.error('Failed to end session');
    } finally {
      isActioning.value = false;
    }
  }

  Future<void> _refreshSessions(int leaseId) async {
    final res = await _api.get(ApiEndpoints.vehicleLeaseSessions(leaseId));
    sessions.assignAll(
      ((res.data as Map)['data'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}
