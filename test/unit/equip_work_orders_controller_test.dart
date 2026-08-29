import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:feros/core/api/api_client.dart';
import 'package:feros/core/api/api_endpoints.dart';
import 'package:feros/core/utils/view_state.dart';
import 'package:feros/app/modules/supervisor/supervisor_equipment_shell/work_orders/controllers/equip_work_orders_controller.dart';
import '../helpers/fake_api_client.dart';

void main() {
  late FakeApiClient api;
  late EquipWorkOrdersController ctrl;

  Map<String, dynamic> pageResponse(List<Map<String, dynamic>> content) => {
        'data': {'content': content, 'totalElements': content.length, 'totalPages': 1},
      };

  setUp(() {
    Get.testMode = true;
    Get.reset();
    api = FakeApiClient();
    Get.put<ApiClient>(api);
    // Create but don't Get.put — avoids onInit triggering premature fetchAll
    ctrl = EquipWorkOrdersController();
  });

  tearDown(Get.reset);

  group('fetchAll', () {
    test('populates workOrders and sets state to success', () async {
      api.stubGet(ApiEndpoints.equipWorkOrders, pageResponse([
        {'id': 1, 'status': 'IN_PROGRESS', 'machineCount': 2},
        {'id': 2, 'status': 'CONFIRMED',   'machineCount': 1},
      ]));

      await ctrl.fetchAll();

      expect(ctrl.workOrders.length, 2);
      expect(ctrl.workOrders.first['id'], 1);
      expect(ctrl.state.value, ViewState.success);
    });

    test('sets state to error when API fails', () async {
      // no stub → FakeApiClient throws
      await ctrl.fetchAll();

      expect(ctrl.state.value, ViewState.error);
      expect(ctrl.workOrders, isEmpty);
    });

    test('sets loading state during fetch', () async {
      var wasLoading = false;
      api.stubGetFn(ApiEndpoints.equipWorkOrders, (_) {
        wasLoading = ctrl.state.value == ViewState.loading;
        return pageResponse([]);
      });

      await ctrl.fetchAll();

      expect(wasLoading, isTrue);
    });
  });

  group('selectStatus', () {
    test('does nothing when same status selected', () async {
      var callCount = 0;
      api.stubGetFn(ApiEndpoints.equipWorkOrders, (_) {
        callCount++;
        return pageResponse([]);
      });
      // Pre-select ALL
      ctrl.selectedStatus.value = 'ALL';

      ctrl.selectStatus('ALL');

      expect(callCount, 0); // fetchAll not triggered
    });

    test('changes selectedStatus and calls fetchAll', () async {
      Map<String, dynamic>? capturedParams;
      api.stubGetFn(ApiEndpoints.equipWorkOrders, (params) {
        capturedParams = params;
        return pageResponse([]);
      });

      ctrl.selectStatus('IN_PROGRESS');

      await Future.delayed(Duration.zero); // let async fetchAll settle
      expect(ctrl.selectedStatus.value, 'IN_PROGRESS');
      expect(capturedParams?['status'], 'IN_PROGRESS');
    });

    test('omits status param when ALL selected', () async {
      Map<String, dynamic>? capturedParams;
      api.stubGetFn(ApiEndpoints.equipWorkOrders, (params) {
        capturedParams = params;
        return pageResponse([]);
      });
      ctrl.selectedStatus.value = 'CONFIRMED'; // start from different

      ctrl.selectStatus('ALL');

      await Future.delayed(Duration.zero);
      expect(capturedParams?.containsKey('status'), isFalse);
    });
  });
}
