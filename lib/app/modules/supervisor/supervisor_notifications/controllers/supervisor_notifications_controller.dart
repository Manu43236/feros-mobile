import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';

class SupervisorNotificationsController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state         = ViewState.loading.obs;
  final notifications = <Map<String, dynamic>>[].obs;

  bool get hasUnread => notifications.any((n) => n['isRead'] == false);

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.notifications);
      final list = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      notifications.value = list.cast<Map<String, dynamic>>();
      state.value = ViewState.success;
      if (hasUnread) markAllRead(silent: true);
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  Future<void> markAllRead({bool silent = false}) async {
    try {
      await _api.patch(ApiEndpoints.notifMarkAllRead);
      if (!silent) {
        notifications.value = notifications
            .map((n) => {...n, 'isRead': true})
            .toList();
      }
    } catch (_) {}
  }
}
