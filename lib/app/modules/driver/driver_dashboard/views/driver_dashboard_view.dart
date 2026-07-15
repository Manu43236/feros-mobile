import 'package:feros/app/modules/driver/driver_shell/controllers/driver_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/delivery_sheet.dart';
import '../../../../../core/widgets/odometer_sheet.dart';
import '../../driver_attendance/views/driver_attendance_sheet.dart';
import '../../driver_payslip/views/driver_payslip_view.dart';
import '../../driver_payslip/bindings/driver_payslip_binding.dart';
import '../../driver_trips/models/lr_model.dart';
import '../../driver_trips/views/driver_trip_detail_view.dart';
import '../../driver_trips/bindings/driver_trip_detail_binding.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/driver_dashboard_controller.dart';

class DriverDashboardView extends GetView<DriverDashboardController> {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDriver = Get.find<AuthService>().currentUser.value?.role == 'DRIVER';
      if (controller.state.value == ViewState.loading) {
        return const ShimmerList(count: 4);
      }
      if (controller.state.value == ViewState.error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              Text(
                'lbl_something_wrong'.tr,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetchDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('btn_retry'.tr),
              ),
            ],
          ),
        );
      }
      final active = controller.activeTrip.value;
      final upcoming = controller.upcomingTrips;
      final nextReady =
          upcoming.firstWhereOrNull((t) => t['lrStatus'] == 'WEIGHT_LOADED') ??
          upcoming.firstOrNull;
      final attended = controller.isAttendanceMarked.value;
      final assignedOrder = controller.assignedOrder.value;
      final assignedVehicle = controller.assignedVehicle.value;

      // ── State 3: ON TRIP ──────────────────────────────────────
      if (active != null) {
        final breakdownActive = controller.hasActiveTripBreakdown.value;
        return _HomeState(
          statusColor: breakdownActive
              ? const Color(0xFFDC2626)
              : const Color(0xFFD97706),
          statusIcon: breakdownActive
              ? Icons.car_crash_outlined
              : Icons.local_shipping,
          statusLabel: breakdownActive
              ? 'lbl_breakdown_reported_waiting'.tr
              : 'lbl_on_trip'.tr,
          tripData: active,
          attended: attended,
          actionLabel: breakdownActive
              ? 'lbl_tap_to_refresh'.tr
              : (isDriver ? 'btn_mark_done'.tr : 'btn_view_trip_details'.tr),
          actionIcon: breakdownActive
              ? Icons.refresh
              : (isDriver ? Icons.check_circle_outline : Icons.info_outline),
          actionColor: breakdownActive
              ? const Color(0xFFDC2626)
              : AppColors.navy,
          onAction: 
          breakdownActive
              ? () => controller.fetchDashboard()
              : (isDriver
                    ? () => _markDoneFromHome(context, active)
                    : () => _openTrip(context, active)),
          secondaryActionLabel: isDriver && !breakdownActive
              ? 'btn_view_trip_details'.tr
              : null,
          onSecondaryAction: isDriver && !breakdownActive
              ? () => _openTrip(context, active)
              : null,
          onCardTap: () => _openTrip(context, active),
          bottomRow: _BottomNav(controller: controller, attended: attended),
          onRefresh: controller.fetchDashboard,
        );
      }

      // ── State 2: TRIP READY ───────────────────────────────────
      if (nextReady != null) {
        final gateBlocked =
            isDriver && controller.isAttendanceEnforced.value && !attended;
        return _HomeState(
          statusColor: const Color(0xFFD97706),
          statusIcon: Icons.inventory_2_outlined,
          statusLabel: 'lbl_trip_ready'.tr,
          tripData: nextReady,
          attended: attended,
          actionLabel: !isDriver
              ? 'btn_view_trip_details'.tr
              : (gateBlocked
                    ? 'lbl_mark_attendance_first'.tr
                    : 'btn_start_trip'.tr),
          actionIcon: !isDriver
              ? Icons.info_outline
              : (gateBlocked ? Icons.lock_outline : Icons.play_circle_outline),
          actionColor: gateBlocked ? const Color(0xFFD97706) : AppColors.navy,
          onAction: !isDriver
              ? () => _openTrip(context, nextReady)
              : (gateBlocked
                    ? () => showMarkAttendanceSheet(
                        context,
                        onMarked: controller.fetchDashboard,
                      )
                    : () => _startTripFromHome(context, nextReady)),
          onCardTap: () => _openTrip(context, nextReady),
          bottomRow: _BottomNav(controller: controller, attended: attended),
          onRefresh: controller.fetchDashboard,
        );
      }

      // ── State 0.5: ORDER ASSIGNED, no LR yet ─────────────────
      if (assignedOrder != null) {
        return _AssignedOrderState(
          orderData: assignedOrder,
          attended: attended,
          controller: controller,
          onRefresh: controller.fetchDashboard,
        );
      }

      // ── State 0: VEHICLE ASSIGNED, no order ──────────────────
      if (assignedVehicle != null) {
        return _AssignedVehicleState(
          vehicleData: assignedVehicle,
          attended: attended,
          controller: controller,
          onRefresh: controller.fetchDashboard,
        );
      }

      // ── State 1: IDLE ─────────────────────────────────────────
      return _IdleState(
        controller: controller,
        onRefresh: controller.fetchDashboard,
      );
    });
  }

  void _markDoneFromHome(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) async {
    final lrId = tripData['lrId'];
    if (lrId == null) return;

    final rawStart = tripData['startOdometer'];
    final startOdm = rawStart != null
        ? double.tryParse(rawStart.toString())
        : null;
    final rawLoaded = tripData['loadedWeight'];
    final loadedWt = rawLoaded != null
        ? double.tryParse(rawLoaded.toString())
        : null;

    final odmResult = await showOdometerSheet(
      context,
      title: 'lbl_end_trip_odm_title'.tr,
      hint: 'lbl_end_odometer_km'.tr,
      buttonLabel: 'btn_next'.tr,
      buttonColor: AppColors.navy,
      instruction: 'lbl_end_trip_instruction'.trParams({
        'value': startOdm?.toStringAsFixed(0) ?? '—',
      }),
      minOdometer: startOdm,
    );
    if (odmResult == null) return;

    final deliveryResult = await showDeliverySheet(
      context,
      endOdometer: odmResult.odometer,
      loadedWeight: loadedWt,
    );
    if (deliveryResult == null) return;

    try {
      final api = Get.find<ApiClient>();
      await api.put(
        ApiEndpoints.lrById(lrId),
        data: {
          'lrStatus': 'DELIVERED',
          'deliveredWeight': deliveryResult.weight,
          'deliveredAt': DateTime.now().toIso8601String(),
          'endOdometer': odmResult.odometer,
        },
      );
      Get.find<DriverDashboardController>().fetchDashboard();
    } catch (_) {
      Get.snackbar(
        'lbl_error'.tr,
        'err_failed_delivery'.tr,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _startTripFromHome(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) async {
    final lrId = tripData['lrId'];
    if (lrId == null) return;

    final rawOdm = tripData['currentVehicleOdometer'];
    final minOdm = rawOdm != null ? double.tryParse(rawOdm.toString()) : null;

    final result = await showOdometerSheet(
      context,
      title: 'lbl_start_trip_odm_title'.tr,
      hint: 'lbl_start_odometer'.tr,
      buttonLabel: 'btn_start_trip'.tr,
      buttonColor: AppColors.navy,
      instruction: 'lbl_start_trip_instruction'.tr,
      minOdometer: minOdm,
    );
    if (result == null) return;

    try {
      final api = Get.find<ApiClient>();
      await api.put(
        ApiEndpoints.lrById(lrId),
        data: {'lrStatus': 'IN_TRANSIT', 'startOdometer': result.odometer},
      );
      Get.find<DriverDashboardController>()
          .fetchDashboard(); // refreshes to ON TRIP state
    } catch (e) {
      final msg = (e as dynamic)?.response?.data?['message'] as String?;
      Get.snackbar(
        'lbl_error'.tr,
        msg ?? 'err_failed_start_trip'.tr,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _openTrip(BuildContext context, Map<String, dynamic> tripData) async {
    final lrId = tripData['lrId'];
    if (lrId == null) {
      Get.find<DriverShellController>().onTabTapped(1);
      return;
    }
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiEndpoints.lrById(lrId));
      final lr = LrModel.fromJson(
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
      );
      Get.to(
        () => const DriverTripDetailView(),
        arguments: lr,
        transition: Transition.cupertino,
        binding: DriverTripDetailBinding(),
      );
    } catch (_) {
      Get.find<DriverShellController>().onTabTapped(1);
    }
  }
}

// ── State 0.5: Order assigned, no LR yet ─────────────────────────────────────
class _AssignedOrderState extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool attended;
  final DriverDashboardController controller;
  final Future<void> Function() onRefresh;
  const _AssignedOrderState({
    required this.orderData,
    required this.attended,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = orderData['vehicleNumber']?.toString() ?? '—';
    final client = orderData['clientName']?.toString() ?? '—';
    final from = orderData['fromCity']?.toString() ?? '—';
    final to = orderData['toCity']?.toString() ?? '—';
    final loadDate = orderData['expectedLoadDate'] as String?;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 160,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.navy.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.navy,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'lbl_order_assigned'.tr,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD97706,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'lbl_waiting_for_lr'.tr,
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Route
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.radio_button_checked,
                                    size: 20,
                                    color: AppColors.navy,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    from,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySemiBold.copyWith(
                                      color: AppColors.navy,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 24,
                                    color: AppColors.mutedText,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    color: AppColors.border,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: AppColors.mutedText,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    to,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySemiBold.copyWith(
                                      color: AppColors.mutedText,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Vehicle + date
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_outlined,
                              size: 18,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vehicle,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.mutedText,
                              ),
                            ),
                            if (loadDate != null) ...[
                              const Spacer(),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _fmtDate(loadDate),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Info message — no action
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD97706,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top_outlined,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'lbl_waiting_for_lr_detail'.tr,
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BottomNav(controller: controller, attended: attended),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const m = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return raw;
    }
  }
}

// ── State 0: Vehicle assigned, no order ──────────────────────────────────────
class _AssignedVehicleState extends StatelessWidget {
  final Map<String, dynamic> vehicleData;
  final bool attended;
  final DriverDashboardController controller;
  final Future<void> Function() onRefresh;
  const _AssignedVehicleState({
    required this.vehicleData,
    required this.attended,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleNumber = vehicleData['vehicleNumber']?.toString() ?? '—';
    final vehicleType = vehicleData['vehicleType']?.toString();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 160,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Vehicle icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 52,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'lbl_vehicle_assigned'.tr,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.isAttendanceMarked.value
                          ? 'lbl_attendance_marked'.tr
                          : 'lbl_mark_attendance_first'.tr,
                      style: AppTextStyles.body.copyWith(
                        color: controller.isAttendanceMarked.value
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vehicle card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.navy.withValues(alpha: 0.15),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus_outlined,
                            size: 28,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicleNumber,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.navy,
                                ),
                              ),
                              if (vehicleType != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  vehicleType,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'lbl_assigned'.tr,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance / Out button
                  Obx(() {
                    final attended = controller.isAttendanceMarked.value;
                    final isOut = controller.markedOutAt.value != null;
                    final canUndo = controller.canUndoOut.value;
                    final duty = controller.dutyLabel.value;

                    if (!attended) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => showMarkAttendanceSheet(
                            context,
                            onMarked: controller.fetchDashboard,
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 26,
                          ),
                          label: Text(
                            'btn_mark_attendance'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    if (!isOut) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.markOut(context),
                          icon: const Icon(Icons.logout, size: 24),
                          label: Text(
                            'btn_mark_out'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    if (canUndo) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.undoOut,
                          icon: const Icon(Icons.undo, size: 24),
                          label: Text(
                            'btn_undo_out'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 22,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${'lbl_out_locked'.tr}${duty != null ? ' · $duty' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _BottomNav(controller: controller, attended: attended),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── State 1: Idle — no trip ───────────────────────────────────────────────────
class _IdleState extends StatelessWidget {
  final DriverDashboardController controller;
  final Future<void> Function() onRefresh;
  const _IdleState({required this.controller, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 160,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Big icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 52,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'lbl_no_active_trip'.tr,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.isAttendanceMarked.value
                          ? 'lbl_attendance_marked'.tr
                          : 'lbl_mark_attendance_first'.tr,
                      style: AppTextStyles.body.copyWith(
                        color: controller.isAttendanceMarked.value
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Attendance / Out button — big, primary
                  Obx(() {
                    final attended = controller.isAttendanceMarked.value;
                    final isOut = controller.markedOutAt.value != null;
                    final canUndo = controller.canUndoOut.value;
                    final duty = controller.dutyLabel.value;

                    if (!attended) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => showMarkAttendanceSheet(
                            context,
                            onMarked: controller.fetchDashboard,
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 26,
                          ),
                          label: Text(
                            'btn_mark_attendance'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    if (!isOut) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.markOut(context),
                          icon: const Icon(Icons.logout, size: 24),
                          label: Text(
                            'btn_mark_out'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    if (canUndo) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.undoOut,
                          icon: const Icon(Icons.undo, size: 24),
                          label: Text(
                            'btn_undo_out'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }
                    // Locked — show duty label chip
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 22,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${'lbl_out_locked'.tr}${duty != null ? ' · $duty' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // My Trips + Salary — big icon tiles
                  Row(
                    children: [
                      Expanded(
                        child: _BigTile(
                          icon: Icons.local_shipping_outlined,
                          label: 'lbl_my_trips'.tr,
                          color: AppColors.navy,
                          onTap: () =>
                              Get.find<DriverShellController>().onTabTapped(1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BigTile(
                          icon: Icons.payments_outlined,
                          label: 'lbl_my_salary'.tr,
                          color: const Color(0xFF7C3AED),
                          onTap: () => Get.to(
                            () => const DriverPayslipView(),
                            binding: DriverPayslipBinding(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Trip count badge
                  Obx(
                    () => controller.upcomingTrips.isNotEmpty
                        ? _InfoBanner(
                            icon: Icons.calendar_today_outlined,
                            text: 'lbl_upcoming_trips'.trParams({
                              'count': '${controller.upcomingTrips.length}',
                            }),
                            color: AppColors.navy,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ), // ConstrainedBox
        ), // SingleChildScrollView
      ), // RefreshIndicator
    );
  }
}

// ── State 2 & 3: Active / Ready trip ─────────────────────────────────────────
class _HomeState extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final Map<String, dynamic> tripData;
  final bool attended;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onCardTap;
  final Widget bottomRow;
  final Future<void> Function() onRefresh;

  const _HomeState({
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.tripData,
    required this.attended,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onCardTap,
    required this.bottomRow,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 160,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trip card with action button(s) inside
                  GestureDetector(
                    onTap: onCardTap,
                    child: _TripInfoCard(
                      tripData: tripData,
                      statusColor: statusColor,
                      actionLabel: actionLabel,
                      actionIcon: actionIcon,
                      actionColor: actionColor,
                      onAction: onAction,
                      secondaryActionLabel: secondaryActionLabel,
                      onSecondaryAction: onSecondaryAction,
                    ),
                  ),
                  const SizedBox(height: 20),

                  bottomRow,
                ],
              ),
            ),
          ), // ConstrainedBox
        ), // SingleChildScrollView
      ), // RefreshIndicator
    );
  }
}

// ── Trip Info Card ────────────────────────────────────────────────────────────
class _TripInfoCard extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final Color statusColor;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  const _TripInfoCard({
    required this.tripData,
    required this.statusColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  String _roleLabel(String? role) {
    switch (role) {
      case 'DRIVER':
        return 'Driver';
      case 'CLEANER':
        return 'Cleaner';
      default:
        return role ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = tripData['fromCity']?.toString() ?? '—';
    final to = tripData['toCity']?.toString() ?? '—';
    final vehicle = tripData['vehicleNumber']?.toString() ?? '—';
    final client = tripData['clientName']?.toString() ?? '—';
    final loadDate = tripData['expectedLoadDate'] as String?;
    final startedByName = tripData['startedByName'] as String?;
    final startedByRole = tripData['startedByRole'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client
          Text(
            client,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 16),

          // Route — big and visual
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      size: 20,
                      color: AppColors.navy,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      from,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: AppColors.navy,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppColors.border,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.location_on, size: 20, color: statusColor),
                    const SizedBox(height: 4),
                    Text(
                      to,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: statusColor,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Vehicle + date
          Row(
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                size: 18,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 6),
              Text(
                vehicle,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
              if (loadDate != null) ...[
                const Spacer(),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  _fmtDate(loadDate),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ],
          ),
          // Started by — audit info
          if (startedByName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started by $startedByName'
                  '${startedByRole != null ? ' (${_roleLabel(startedByRole)})' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Primary action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 20),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondaryAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  secondaryActionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const m = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Bottom Nav Row ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final DriverDashboardController controller;
  final bool attended;
  const _BottomNav({required this.controller, required this.attended});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOut = controller.markedOutAt.value != null;
      final canUndo = controller.canUndoOut.value;
      final duty = controller.dutyLabel.value;

      IconData attIcon;
      String attLabel;
      Color attColor;
      VoidCallback? attTap;

      if (!attended) {
        attIcon = Icons.check_circle_outline;
        attLabel = 'nav_attendance'.tr;
        attColor = const Color(0xFFD97706);
        attTap = () => showMarkAttendanceSheet(
          context,
          onMarked: controller.fetchDashboard,
        );
      } else if (!isOut) {
        attIcon = Icons.logout;
        attLabel = 'btn_mark_out'.tr;
        attColor = const Color(0xFFDC2626);
        attTap = () => controller.markOut(context);
      } else if (canUndo) {
        attIcon = Icons.undo;
        attLabel = 'btn_undo_out'.tr;
        attColor = const Color(0xFFD97706);
        attTap = () => controller.undoOut();
      } else {
        attIcon = Icons.check_circle;
        attLabel = duty ?? 'lbl_out_locked'.tr;
        attColor = const Color(0xFF16A34A);
        attTap = null;
      }

      return Row(
        children: [
          Expanded(
            child: _SmallTile(
              icon: attIcon,
              label: attLabel,
              color: attColor,
              onTap: attTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallTile(
              icon: Icons.payments_outlined,
              label: 'lbl_my_salary'.tr,
              color: const Color(0xFF7C3AED),
              onTap: () => Get.to(
                () => const DriverPayslipView(),
                binding: DriverPayslipBinding(),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Big Tile ──────────────────────────────────────────────────────────────────
class _BigTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small Tile ────────────────────────────────────────────────────────────────
class _SmallTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _SmallTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
