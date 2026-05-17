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
  final plans        = <Map<String, dynamic>>[].obs;
  final vehicleCount = 0.obs;
  final userCount    = 0.obs;

  // Upgrade form state
  final selectedPlanId  = Rx<int?>(null);
  final vehicleInput    = ''.obs;
  final billingCycle    = 'MONTHLY'.obs;
  final upgradeNotes    = ''.obs;
  final upgradeState    = ViewState.initial.obs;
  final upgradeSent     = false.obs;

  static const cycles = [
    {'value': 'MONTHLY',      'label': 'Monthly'},
    {'value': 'THREE_MONTHS', 'label': '3 Months'},
    {'value': 'SIX_MONTHS',  'label': '6 Months'},
    {'value': 'YEARLY',       'label': 'Annual'},
  ];

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
        _fetchPlans(),
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

  Future<void> _fetchPlans() async {
    try {
      final res = await _api.get('/subscription-plans');
      final all = ((res.data as Map)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Only paid plans, sorted by minVehicles
      plans.value = all
          .where((p) => (p['pricePerVehicle'] as num? ?? 0) > 0)
          .toList()
        ..sort((a, b) =>
            ((a['minVehicles'] as num? ?? 0))
                .compareTo((b['minVehicles'] as num? ?? 0)));
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

  // Upgrade estimate
  Map<String, dynamic>? get estimate {
    final planId = selectedPlanId.value;
    if (planId == null) return null;
    final vCount = int.tryParse(vehicleInput.value.trim()) ?? 0;
    if (vCount <= 0) return null;
    final plan = plans.firstWhereOrNull((p) => p['id'] == planId);
    if (plan == null) return null;

    final pricePerVehicle =
        (plan['pricePerVehicle'] as num? ?? 0).toDouble();
    final months = _cycleMonths(billingCycle.value);
    final base   = pricePerVehicle * vCount * months;
    final gst    = base * 0.18;
    return {
      'base':   base,
      'gst':    gst,
      'total':  base + gst,
      'months': months,
    };
  }

  int _cycleMonths(String cycle) {
    switch (cycle) {
      case 'THREE_MONTHS': return 3;
      case 'SIX_MONTHS':  return 6;
      case 'YEARLY':       return 12;
      default:             return 1;
    }
  }

  void selectPlan(int id) {
    selectedPlanId.value = id;
    final plan = plans.firstWhereOrNull((p) => p['id'] == id);
    if (plan != null) {
      vehicleInput.value =
          '${(plan['minVehicles'] as num? ?? 1).toInt()}';
    }
  }

  void setVehicleInput(String v) {
    vehicleInput.value = v;
    // Auto-select plan that matches vehicle count
    final count = int.tryParse(v.trim()) ?? 0;
    if (count > 0) {
      final matched = plans.firstWhereOrNull((p) {
        final min = (p['minVehicles'] as num? ?? 0).toInt();
        final max = (p['maxVehicles'] as num? ?? -1).toInt();
        return count >= min && (max == -1 || count <= max);
      });
      if (matched != null) {
        selectedPlanId.value = (matched['id'] as num).toInt();
      }
    }
  }

  Future<bool> submitUpgradeRequest() async {
    final planId = selectedPlanId.value;
    final vCount = int.tryParse(vehicleInput.value.trim()) ?? 0;
    if (planId == null || vCount <= 0) return false;

    upgradeState.value = ViewState.loading;
    try {
      await _api.post('/subscriptions/upgrade-request', data: {
        'planId':        planId,
        'vehicleCount':  vCount,
        'billingCycle':  billingCycle.value,
        if (upgradeNotes.value.trim().isNotEmpty)
          'notes': upgradeNotes.value.trim(),
      });
      upgradeSent.value  = true;
      upgradeState.value = ViewState.success;
      return true;
    } catch (e) {
      debugPrint('[Subscription] upgrade: $e');
      upgradeState.value = ViewState.error;
      return false;
    }
  }

  void resetUpgradeForm() {
    upgradeSent.value     = false;
    selectedPlanId.value  = null;
    vehicleInput.value    = '';
    upgradeNotes.value    = '';
    upgradeState.value    = ViewState.initial;
  }
}
