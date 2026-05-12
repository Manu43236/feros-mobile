import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_controller.dart';

class DriverDashboard extends StatelessWidget {
  final DashboardController controller;
  const DriverDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Stat Cards ─────────────────────────────────────────
        Obx(() => Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Trips Today',
                value: '${controller.totalTrips.value}',
                icon: Icons.local_shipping_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Attendance',
                value: controller.isAttendanceMarked.value ? 'Present' : 'Absent',
                icon: Icons.check_circle_outline,
                borderColor: controller.isAttendanceMarked.value
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                valueColor: controller.isAttendanceMarked.value
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${controller.pendingTrips.value}',
                icon: Icons.pending_actions_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
          ],
        )),
        const SizedBox(height: 24),

        // ── Upcoming Trip ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Trip',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('View All',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => controller.upcomingTrip.value != null
            ? _TripCard(trip: controller.upcomingTrip.value!)
            : _EmptyTrip()),
        const SizedBox(height: 24),

        // ── Quick Actions ──────────────────────────────────────
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.check_circle_outline,
                label: 'Mark\nAttendance',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.local_shipping_outlined,
                label: 'My\nTrips',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.payments_outlined,
                label: 'My\nPayroll',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: borderColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodySemiBold.copyWith(
              color: valueColor ?? AppColors.navy,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LR + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip['lrNumber']?.toString() ?? '—',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              ),
              _StatusChip(status: trip['status']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 8),
          // Client
          Text(
            trip['clientName']?.toString() ?? '—',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          // Route
          Row(
            children: [
              Expanded(
                child: Text(
                  trip['fromLocation']?.toString() ?? '—',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip['toLocation']?.toString() ?? '—',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('View Details',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text('No upcoming trips',
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.navy),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}
