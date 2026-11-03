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

  // ── All active machines (standalone — mirrors vehicle breakdown) ───────────
  Future<void> _loadMachines() async {
    try {
      final res  = await _api.get(ApiEndpoints.equipmentList);
      final list = ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      machines.assignAll(list
          .where((e) => e['isActive'] == true && e['workStatus'] != 'BREAKDOWN')
          .map((e) => {
                'equipmentId': e['id'],
                'serialNumber': e['serialNumber'] ?? e['registrationNumber'],
                'equipmentTypeName': e['equipmentTypeName'],
              })
          .toList());
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
