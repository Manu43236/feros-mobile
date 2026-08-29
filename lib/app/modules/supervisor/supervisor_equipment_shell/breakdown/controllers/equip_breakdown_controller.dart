import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';

class EquipBreakdownController extends GetxController {
  final _api = Get.find<ApiClient>();

  final machines       = <Map<String, dynamic>>[].obs;
  final machinesLoaded = false.obs;
  final submitting     = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMachines();
  }

  // ── Flatten machines from active work orders ──────────────────────────────
  Future<void> _loadMachines() async {
    try {
      final res = await _api.get(
        ApiEndpoints.equipWorkOrders,
        params: {'page': '0', 'size': '100', 'status': 'IN_PROGRESS'},
      );
      final page = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
      final list = (page['content'] as List? ?? []).cast<Map<String, dynamic>>();

      final seen = <int>{};
      final result = <Map<String, dynamic>>[];
      for (final wo in list) {
        final assignments =
            (wo['assignments'] as List? ?? []).cast<Map<String, dynamic>>();
        for (final a in assignments) {
          final eqId = a['equipmentId'] as int?;
          if (eqId != null && seen.add(eqId)) {
            result.add(a);
          }
        }
      }
      machines.assignAll(result);
    } catch (e) {
      debugPrint('[EquipBreakdown] load machines: $e');
    } finally {
      machinesLoaded.value = true;
    }
  }

  // ── Report a breakdown ────────────────────────────────────────────────────
  Future<bool> reportBreakdown({
    required int equipmentId,
    required String reason,
    String? location,
    String? notes,
  }) async {
    submitting.value = true;
    try {
      await _api.post(
        ApiEndpoints.equipBreakdowns(equipmentId),
        data: {
          'reason': reason,
          if (location != null && location.isNotEmpty) 'location': location,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[EquipBreakdown] report: $e');
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
