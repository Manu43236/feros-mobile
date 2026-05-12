import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/delivery_sheet.dart';
import '../../../../core/widgets/odometer_sheet.dart';
import '../../attendance/views/attendance_sheet.dart';
import '../../payslip/views/payslip_view.dart';
import '../../shell/controllers/shell_controller.dart';
import '../../trips/models/lr_model.dart';
import '../../trips/views/trip_detail_view.dart';
import '../controllers/dashboard_controller.dart';

class DriverDashboard extends StatelessWidget {
  final DashboardController controller;
  const DriverDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active  = controller.activeTrip.value;
      final upcoming = controller.upcomingTrips;
      final nextReady = upcoming.firstWhereOrNull(
          (t) => t['lrStatus'] == 'WEIGHT_LOADED') ?? upcoming.firstOrNull;
      final attended = controller.isAttendanceMarked.value;

      // ── State 3: ON TRIP ──────────────────────────────────────
      if (active != null) {
        return _HomeState(
          statusColor: const Color(0xFFD97706),
          statusIcon: Icons.local_shipping,
          statusLabel: 'ON TRIP',
          tripData: active,
          attended: attended,
          actionLabel: 'Mark as Done',
          actionIcon: Icons.check_circle_outline,
          onAction: () => _markDoneFromHome(context, active),
          secondaryActionLabel: 'View Trip Details',
          onSecondaryAction: () => _openTrip(context, active),
          onCardTap: () => _openTrip(context, active),
          bottomRow: _BottomNav(controller: controller, attended: attended),
        );
      }

      // ── State 2: TRIP READY ───────────────────────────────────
      if (nextReady != null) {
        return _HomeState(
          statusColor: const Color(0xFFD97706),
          statusIcon: Icons.inventory_2_outlined,
          statusLabel: 'TRIP READY',
          tripData: nextReady,
          attended: attended,
          actionLabel: 'Start Trip',
          actionIcon: Icons.play_circle_outline,
          onAction: () => _startTripFromHome(context, nextReady),
          onCardTap: () => _openTrip(context, nextReady),
          bottomRow: _BottomNav(controller: controller, attended: attended),
        );
      }

      // ── State 1: IDLE ─────────────────────────────────────────
      return _IdleState(controller: controller);
    });
  }

  void _markDoneFromHome(BuildContext context, Map<String, dynamic> tripData) async {
    final lrId = tripData['lrId'];
    if (lrId == null) return;

    final odmResult = await showOdometerSheet(
      context,
      title: 'End Trip — Record ODM',
      hint: 'End Odometer (km)',
      buttonLabel: 'Next',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer on arrival.',
    );
    if (odmResult == null) return;

    final deliveryResult = await showDeliverySheet(
      context,
      endOdometer: odmResult.odometer,
    );
    if (deliveryResult == null) return;

    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(lrId), data: {
        'lrStatus': 'DELIVERED',
        'deliveredWeight': deliveryResult.weight,
        'deliveredAt': DateTime.now().toIso8601String(),
        'endOdometer': odmResult.odometer,
      });
      controller.fetchDashboard();
    } catch (_) {
      Get.snackbar('Error', 'Failed to confirm delivery',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _startTripFromHome(BuildContext context, Map<String, dynamic> tripData) async {
    final lrId = tripData['lrId'];
    if (lrId == null) return;

    final result = await showOdometerSheet(
      context,
      title: 'Start Trip — Record ODM',
      hint: 'Start Odometer (km)',
      buttonLabel: 'Start Trip',
      buttonColor: AppColors.navy,
      instruction: 'Take a photo of the odometer before departure.',
    );
    if (result == null) return;

    try {
      final api = Get.find<ApiClient>();
      await api.put(ApiEndpoints.lrById(lrId), data: {
        'lrStatus': 'IN_TRANSIT',
        'startOdometer': result.odometer,
      });
      controller.fetchDashboard(); // refreshes to ON TRIP state
    } catch (_) {
      Get.snackbar('Error', 'Failed to start trip',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _openTrip(BuildContext context, Map<String, dynamic> tripData) async {
    final lrId = tripData['lrId'];
    if (lrId == null) {
      Get.find<ShellController>().onTabTapped(1);
      return;
    }
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiEndpoints.lrById(lrId));
      final lr = LrModel.fromJson(
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
      Get.to(() => TripDetailView(lr: lr), transition: Transition.cupertino);
    } catch (_) {
      Get.find<ShellController>().onTabTapped(1);
    }
  }
}

// ── State 1: Idle — no trip ───────────────────────────────────────────────────
class _IdleState extends StatelessWidget {
  final DashboardController controller;
  const _IdleState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Big icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  size: 52, color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            Text('No Active Trip',
                style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Obx(() => Text(
              controller.isAttendanceMarked.value
                  ? 'Attendance marked ✓'
                  : 'Mark your attendance first',
              style: AppTextStyles.body.copyWith(
                color: controller.isAttendanceMarked.value
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            )),
            const SizedBox(height: 36),

            // Attendance button — big, primary
            Obx(() => controller.isAttendanceMarked.value
                ? const SizedBox.shrink()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showMarkAttendanceSheet(
                        context,
                        onMarked: controller.fetchDashboard,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 26),
                      label: const Text('MARK ATTENDANCE',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )),
            const SizedBox(height: 16),

            // My Trips + Salary — big icon tiles
            Row(
              children: [
                Expanded(
                  child: _BigTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'My Trips',
                    color: AppColors.navy,
                    onTap: () =>
                        Get.find<ShellController>().onTabTapped(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BigTile(
                    icon: Icons.payments_outlined,
                    label: 'My Salary',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Get.to(() => const PayslipView()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trip count badge
            Obx(() => controller.upcomingTrips.isNotEmpty
                ? _InfoBanner(
                    icon: Icons.calendar_today_outlined,
                    text:
                        '${controller.upcomingTrips.length} upcoming trip(s) scheduled',
                    color: AppColors.navy,
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
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
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onCardTap;
  final Widget bottomRow;

  const _HomeState({
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.tripData,
    required this.attended,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onCardTap,
    required this.bottomRow,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 10),
                  Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1.2)),
                  const Spacer(),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: statusColor),
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
    );
  }
}

// ── Trip Info Card ────────────────────────────────────────────────────────────
class _TripInfoCard extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final Color statusColor;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  const _TripInfoCard({
    required this.tripData,
    required this.statusColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  String _roleLabel(String? role) {
    switch (role) {
      case 'DRIVER':   return 'Driver';
      case 'CLEANER':  return 'Cleaner';
      default:         return role ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = tripData['fromCity']?.toString() ?? '—';
    final to   = tripData['toCity']?.toString() ?? '—';
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
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client
          Text(client,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
          const SizedBox(height: 16),

          // Route — big and visual
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 20, color: AppColors.navy),
                    const SizedBox(height: 4),
                    Text(from,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySemiBold
                            .copyWith(color: AppColors.navy, fontSize: 15),
                        maxLines: 2),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.arrow_forward,
                        size: 24, color: AppColors.mutedText),
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
                    Text(to,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySemiBold.copyWith(
                            color: statusColor, fontSize: 15),
                        maxLines: 2),
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
              const Icon(Icons.directions_bus_outlined,
                  size: 18, color: AppColors.mutedText),
              const SizedBox(width: 6),
              Text(vehicle,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedText)),
              if (loadDate != null) ...[
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(_fmtDate(loadDate),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ],
          ),
          // Started by — audit info
          if (startedByName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  'Started by $startedByName'
                  '${startedByRole != null ? ' (${_roleLabel(startedByRole)})' : ''}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText),
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
              label: Text(actionLabel,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(secondaryActionLabel!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
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
      const m = ['', 'Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Bottom Nav Row ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final DashboardController controller;
  final bool attended;
  const _BottomNav({required this.controller, required this.attended});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallTile(
            icon: attended
                ? Icons.check_circle
                : Icons.check_circle_outline,
            label: attended ? 'Present ✓' : 'Attendance',
            color: attended
                ? const Color(0xFF16A34A)
                : const Color(0xFFD97706),
            onTap: attended
                ? null
                : () => showMarkAttendanceSheet(
                      context,
                      onMarked: controller.fetchDashboard,
                    ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallTile(
            icon: Icons.payments_outlined,
            label: 'My Salary',
            color: const Color(0xFF7C3AED),
            onTap: () => Get.to(() => const PayslipView()),
          ),
        ),
      ],
    );
  }
}

// ── Big Tile ──────────────────────────────────────────────────────────────────
class _BigTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
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
  const _SmallTile(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null
              ? color.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: color),
                textAlign: TextAlign.center),
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
  const _InfoBanner(
      {required this.icon, required this.text, required this.color});

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
          Text(text,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
