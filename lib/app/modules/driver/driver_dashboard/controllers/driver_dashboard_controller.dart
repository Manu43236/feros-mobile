import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/view_state.dart';

class DriverDashboardController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state = ViewState.initial.obs;

  final isAttendanceMarked   = false.obs;
  final isAttendanceEnforced = false.obs;
  final unreadNotifications  = 0.obs;

  final activeTrip             = Rxn<Map<String, dynamic>>();
  final upcomingTrips          = <Map<String, dynamic>>[].obs;
  final hasActiveTripBreakdown = false.obs;
  final assignedVehicle        = Rxn<Map<String, dynamic>>();
  final assignedOrder          = Rxn<Map<String, dynamic>>();

  // Duty / out tracking
  final markedOutAt  = Rxn<DateTime>();
  final canUndoOut   = false.obs;
  final dutyLabel    = RxnString();

  @override
  void onReady() {
    super.onReady();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state.value = ViewState.loading;
    try {
      final res  = await _api.get(ApiEndpoints.dashboard);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      isAttendanceMarked.value   = data['attendanceMarked']    as bool? ?? false;
      isAttendanceEnforced.value = data['attendanceEnforced']  as bool? ?? false;
      unreadNotifications.value  = data['unreadNotifications'] as int?  ?? 0;

      final trip = data['activeTrip'] as Map<String, dynamic>?;
      activeTrip.value = trip;
      hasActiveTripBreakdown.value = trip?['hasActiveBreakdown'] as bool? ?? false;

      final trips = (data['upcomingTrips'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      upcomingTrips.value = trips;

      assignedVehicle.value = data['assignedVehicle'] as Map<String, dynamic>?;
      assignedOrder.value   = data['assignedOrder']   as Map<String, dynamic>?;

      final outStr = data['markedOutAt'] as String?;
      markedOutAt.value = outStr != null ? DateTime.tryParse(outStr) : null;
      canUndoOut.value  = data['canUndoOut'] as bool? ?? false;
      dutyLabel.value   = data['dutyLabel']  as String?;

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  Future<void> markOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark Out?'),
        content: const Text(
            'This will record your end-of-duty time for today. You can undo this within 10 minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Mark Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.post(ApiEndpoints.attendanceMarkOut, data: {});
      fetchDashboard();
    } catch (e) {
      final msg = (e as dynamic)?.response?.data?['message'] as String?;
      Get.snackbar('Error', msg ?? 'Failed to mark out',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> undoOut() async {
    try {
      await _api.post(ApiEndpoints.attendanceUndoOut, data: {});
      fetchDashboard();
    } catch (e) {
      final msg = (e as dynamic)?.response?.data?['message'] as String?;
      Get.snackbar('Error', msg ?? 'Undo window expired',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
