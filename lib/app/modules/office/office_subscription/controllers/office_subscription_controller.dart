import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class OfficeSubscriptionController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final subscription = Rx<Map<String, dynamic>?>(null);
  final invoices     = <Map<String, dynamic>>[].obs;
  final vehicleCount = 0.obs;
  final userCount    = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      await Future.wait([
        _fetchSubscription(),
        _fetchInvoices(),
        _fetchVehicleCount(),
        _fetchUserCount(),
      ]);
      state.value = ViewState.success;
    } catch (e) {
      debugPrint('[Subscription] fetchAll: $e');
      state.value = ViewState.error;
    }
  }

  Future<void> _fetchSubscription() async {
    final res = await _api.get(ApiEndpoints.mySubscription);
    subscription.value =
        (res.data as Map)['data'] as Map<String, dynamic>?;
  }

  Future<void> _fetchInvoices() async {
    try {
      final res = await _api.get(ApiEndpoints.mySubscriptionInvoices);
      invoices.value = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {}
  }

  Future<void> _fetchVehicleCount() async {
    try {
      final res = await _api.get(ApiEndpoints.vehicles);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      vehicleCount.value =
          list.where((v) => v['isActive'] != false).length;
    } catch (_) {}
  }

  Future<void> _fetchUserCount() async {
    try {
      final res = await _api.get(ApiEndpoints.users);
      final list = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      userCount.value =
          list.where((u) => u['isActive'] != false).length;
    } catch (_) {}
  }

  // ── Derived ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? get sub => subscription.value;

  String get status => sub?['status'] as String? ?? '';

  int? get daysLeft {
    final end = sub?['endDate'] as String?;
    if (end == null) return null;
    final d = DateTime.tryParse(end);
    if (d == null) return null;
    return d.difference(DateTime.now()).inDays;
  }

  int get vehicleLimit =>
      (sub?['maxLorries'] as num? ?? sub?['vehicleCount'] as num? ?? -1)
          .toInt();

  int get userLimit =>
      (sub?['maxUsers'] as num? ?? -1).toInt();

  // Paid plan features
  bool get hasCreditNotes  => sub?['hasCreditNotes']  as bool? ?? false;
  bool get hasFuelLogs     => sub?['hasFuelLogs']     as bool? ?? false;
  bool get hasMeterReadings => (sub?['hasMeterReadings'] as bool?) ?? false;
  bool get hasVehicleServices => (sub?['hasVehicleServices'] as bool?) ?? false;
  bool get hasAttendance   => sub?['hasAttendance']   as bool? ?? false;
  bool get hasPayroll      => sub?['hasPayroll']      as bool? ?? false;
  bool get hasInventory    => sub?['hasInventory']    as bool? ?? false;
  bool get hasReports      => sub?['hasReports']      as bool? ?? false;

}
