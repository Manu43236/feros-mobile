import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:feros/core/api/api_client.dart';
import 'package:feros/core/api/api_endpoints.dart';
import 'package:feros/app/modules/supervisor/supervisor_equipment_shell/breakdown/controllers/equip_breakdown_controller.dart';
import '../helpers/fake_api_client.dart';

void main() {
  late FakeApiClient api;

  Map<String, dynamic> pageOf(List<Map<String, dynamic>> wos) => {
        'data': {'content': wos, 'totalElements': wos.length, 'totalPages': 1},
      };

  setUp(() {
    Get.testMode = true;
    Get.reset();
    api = FakeApiClient();
    Get.put<ApiClient>(api);
  });

  tearDown(Get.reset);

  // ── _loadMachines (triggered by onInit) ─────────────────────────────────────

  group('machine loading', () {
    test('extracts machines from IN_PROGRESS WO assignments', () async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageOf([
        {
          'id': 1,
          'status': 'IN_PROGRESS',
          'assignments': [
            {'id': 10, 'equipmentId': 101, 'equipmentName': 'Excavator A'},
            {'id': 11, 'equipmentId': 102, 'equipmentName': 'Crane B'},
          ],
        },
      ]));

      final ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero); // let async _loadMachines complete

      expect(ctrl.machines.length, 2);
      expect(ctrl.machinesLoaded.value, isTrue);
    });

    test('deduplicates machines by equipmentId across WOs', () async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageOf([
        {
          'id': 1,
          'assignments': [
            {'id': 10, 'equipmentId': 101, 'equipmentName': 'Excavator A'},
          ],
        },
        {
          'id': 2,
          'assignments': [
            {'id': 20, 'equipmentId': 101, 'equipmentName': 'Excavator A'}, // duplicate
            {'id': 21, 'equipmentId': 103, 'equipmentName': 'Dozer C'},
          ],
        },
      ]));

      final ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero);

      expect(ctrl.machines.length, 2);
      expect(ctrl.machines.map((m) => m['equipmentId']).toSet(), {101, 103});
    });

    test('handles empty WO list gracefully', () async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageOf([]));

      final ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero);

      expect(ctrl.machines, isEmpty);
      expect(ctrl.machinesLoaded.value, isTrue);
    });

    test('handles WOs with no assignments key', () async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageOf([
        {'id': 1, 'status': 'IN_PROGRESS'}, // no 'assignments'
      ]));

      final ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero);

      expect(ctrl.machines, isEmpty);
      expect(ctrl.machinesLoaded.value, isTrue);
    });

    test('sets machinesLoaded=true even on API error', () async {
      // no GET stub → throws inside _loadMachines catch block
      final ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero);

      expect(ctrl.machinesLoaded.value, isTrue);
      expect(ctrl.machines, isEmpty);
    });
  });

  // ── reportBreakdown ────────────────────────────────────────────────────────

  group('reportBreakdown', () {
    late EquipBreakdownController ctrl;

    setUp(() async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageOf([]));
      ctrl = Get.put(EquipBreakdownController());
      await Future.delayed(Duration.zero);
    });

    test('posts to correct endpoint and returns true', () async {
      const equipId = 101;
      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.equipBreakdowns(equipId), (body) {
        capturedBody = body as Map<String, dynamic>;
        return {'data': {}};
      });

      final ok = await ctrl.reportBreakdown(
        equipmentId: equipId,
        reason: 'Hydraulic leak',
        location: 'Site A',
        notes: 'Urgent',
      );

      expect(ok, isTrue);
      expect(capturedBody?['reason'], 'Hydraulic leak');
      expect(capturedBody?['location'], 'Site A');
      expect(capturedBody?['notes'], 'Urgent');
    });

    test('omits empty location and notes from body', () async {
      const equipId = 101;
      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.equipBreakdowns(equipId), (body) {
        capturedBody = body as Map<String, dynamic>;
        return {'data': {}};
      });

      await ctrl.reportBreakdown(
        equipmentId: equipId,
        reason: 'Engine failure',
        location: '',
        notes: '',
      );

      expect(capturedBody?.containsKey('location'), isFalse);
      expect(capturedBody?.containsKey('notes'), isFalse);
    });

    test('returns false on API error', () async {
      final ok = await ctrl.reportBreakdown(
        equipmentId: 999,
        reason: 'Breakdown',
      );
      expect(ok, isFalse);
    });

    test('sets submitting=true during call, clears after', () async {
      bool? wasSubmitting;
      api.stubPostFn(ApiEndpoints.equipBreakdowns(101), (body) {
        wasSubmitting = ctrl.submitting.value;
        return {'data': {}};
      });

      await ctrl.reportBreakdown(equipmentId: 101, reason: 'Test');

      expect(wasSubmitting, isTrue);
      expect(ctrl.submitting.value, isFalse); // cleared in finally
    });
  });
}
