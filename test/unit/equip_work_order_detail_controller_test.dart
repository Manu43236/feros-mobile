import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:feros/core/api/api_client.dart';
import 'package:feros/core/api/api_endpoints.dart';
import 'package:feros/core/services/upload_service.dart';
import 'package:feros/core/utils/view_state.dart';
import 'package:feros/app/modules/supervisor/supervisor_equipment_shell/work_orders/controllers/equip_work_order_detail_controller.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/fake_upload_service.dart';

// Skip onInit to avoid reading Get.arguments and auto-calling fetchDetail.
class _TestableDetailController extends EquipWorkOrderDetailController {
  _TestableDetailController(int id) {
    woId = id;
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

const int kWoId = 42;

Map<String, dynamic> _detailResponse({
  Map<String, dynamic>? wo,
  List? assignments,
  List? logs,
}) =>
    {
      'data': {
        'workOrder':   wo          ?? {'id': kWoId, 'status': 'IN_PROGRESS'},
        'assignments': assignments ?? [],
        'logs':        logs        ?? [],
      },
    };

FakeApiClient _buildApi() {
  final api = FakeApiClient();
  Get.put<ApiClient>(api);
  Get.put<UploadService>(FakeUploadService());
  return api;
}

void main() {
  tearDown(Get.reset);

  // ── fetchDetail (no snackbar — plain test) ────────────────────────────────

  group('fetchDetail', () {
    late FakeApiClient api;
    late _TestableDetailController ctrl;

    setUp(() {
      Get.testMode = true;
      Get.reset();
      api  = _buildApi();
      ctrl = _TestableDetailController(kWoId);
    });

    test('populates wo, assignments and logs on success', () async {
      api.stubGet(ApiEndpoints.equipWorkOrderById(kWoId), _detailResponse(
        wo: {'id': kWoId, 'status': 'IN_PROGRESS'},
        assignments: [
          {'id': 10, 'equipmentId': 1, 'equipmentName': 'Excavator A'},
        ],
        logs: [
          {'id': 100, 'logDate': '2026-08-20', 'workingHours': 8.0},
          {'id': 101, 'logDate': '2026-08-21', 'workingHours': 6.0},
        ],
      ));

      await ctrl.fetchDetail();

      expect(ctrl.wo.value?['id'], kWoId);
      expect(ctrl.assignments.length, 1);
      expect(ctrl.logs.length, 2);
      expect(ctrl.state.value, ViewState.success);
    });

    test('sorts logs descending by logDate', () async {
      api.stubGet(ApiEndpoints.equipWorkOrderById(kWoId), _detailResponse(
        logs: [
          {'id': 100, 'logDate': '2026-08-18'},
          {'id': 101, 'logDate': '2026-08-22'},
          {'id': 102, 'logDate': '2026-08-20'},
        ],
      ));

      await ctrl.fetchDetail();

      expect(ctrl.logs.map((l) => l['logDate']).toList(),
          ['2026-08-22', '2026-08-20', '2026-08-18']);
    });

    test('sets error state when API fails', () async {
      await ctrl.fetchDetail(); // no stub → throws

      expect(ctrl.state.value, ViewState.error);
      expect(ctrl.wo.value, isNull);
    });
  });

  // ── Action tests (require snackbar → testWidgets + GetMaterialApp) ────────

  group('startSession', () {
    testWidgets('returns true and refreshes detail on success',
        (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final api  = _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      api.stubPost(ApiEndpoints.equipWoStartSession(kWoId, 10), {'data': {}});
      api.stubGet(ApiEndpoints.equipWorkOrderById(kWoId), _detailResponse());

      final result = await ctrl.startSession(
        10,
        startMeter: 1200.0,
        operatorType: 'OWN',
        operatorStaffId: 5,
      );
      await tester.pump(const Duration(seconds: 5));

      expect(result, isTrue);
    });

    testWidgets('returns false and clears sessionLoading on API error',
        (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      final result = await ctrl.startSession(
        10,
        startMeter: 100,
        operatorType: 'OWN',
      );
      await tester.pump(const Duration(seconds: 5));

      expect(result, isFalse);
      expect(ctrl.sessionLoading.value, isNull);
    });
  });

  group('stopSession', () {
    testWidgets('calls stop endpoint and returns true', (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final api  = _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      api.stubPut(ApiEndpoints.equipWoStopSession(kWoId, 10), {'data': {}});
      api.stubGet(ApiEndpoints.equipWorkOrderById(kWoId), _detailResponse());

      final result = await ctrl.stopSession(10, endMeter: 1350.0);
      await tester.pump(const Duration(seconds: 5));

      expect(result, isTrue);
    });

    testWidgets('returns false on API error', (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      final result = await ctrl.stopSession(10, endMeter: 1350.0);
      await tester.pump(const Duration(seconds: 5));

      expect(result, isFalse);
    });
  });

  group('addLog', () {
    testWidgets('posts to logs endpoint and returns true', (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final api  = _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.equipWoLogs(kWoId), (body) {
        capturedBody = body as Map<String, dynamic>?;
        return {'data': {'id': 200}};
      });
      api.stubGet(ApiEndpoints.equipWorkOrderById(kWoId), _detailResponse());

      final result = await ctrl.addLog({
        'machineAssignmentId': 10,
        'logDate': '2026-08-25',
        'workingHours': 7.5,
      });
      await tester.pump(const Duration(seconds: 5));

      expect(result, isTrue);
      expect(capturedBody?['workingHours'], 7.5);
    });

    testWidgets('returns false and clears isAddingLog on error',
        (tester) async {
      Get.testMode = true;
      Get.reset();
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      _buildApi();
      final ctrl = _TestableDetailController(kWoId);

      final result = await ctrl.addLog({'machineAssignmentId': 10});
      await tester.pump(const Duration(seconds: 5));

      expect(result, isFalse);
      expect(ctrl.isAddingLog.value, isFalse);
    });
  });
}
