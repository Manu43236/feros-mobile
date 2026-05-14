import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../controllers/supervisor_dashboard_controller.dart';

class SupervisorDashboard extends StatelessWidget {
  final SupervisorDashboardController controller;
  const SupervisorDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Stat Cards ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Orders',
                value: '${controller.totalOrders.value}',
                icon: Icons.assignment_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Active Orders',
                value: '${controller.activeOrders.value}',
                icon: Icons.local_shipping_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${controller.pendingAssignments.value}',
                icon: Icons.pending_actions_outlined,
                borderColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Attendance + Notifications ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Present Today',
                value: '${controller.todayPresent.value}',
                icon: Icons.fact_check_outlined,
                borderColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Notifications',
                value: '${controller.unreadNotifications.value}',
                icon: Icons.notifications_outlined,
                borderColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Active Trips ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Trips',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${controller.activeTrips.length} IN TRANSIT',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFD97706),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (controller.activeTrips.isEmpty)
          _EmptySection(
            icon: Icons.local_shipping_outlined,
            label: 'No active trips',
          )
        else
          ...controller.activeTrips.map((trip) => _ActiveTripCard(trip: trip)),

        const SizedBox(height: 24),

        // ── Pending Assignments ────────────────────────────────────
        if (controller.pendingAssignments.value > 0) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                '${controller.pendingAssignments.value} order(s) waiting for vehicle assignment',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to Orders tab — tab index 1
                // Will wire up when shell is connected
              },
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('View Pending Orders'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    ));
  }
}

// ── Active Trip Card ───────────────────────────────────────────────────────────
class _ActiveTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final from    = trip['fromCity']?.toString() ?? '—';
    final to      = trip['toCity']?.toString() ?? '—';
    final vehicle = trip['vehicleNumber']?.toString() ?? '—';
    final client  = trip['clientName']?.toString() ?? '—';
    final eta     = trip['expectedDeliveryDate'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: const Color(0xFFD97706), width: 3),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_shipping,
                size: 20, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client,
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: AppColors.navy, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(from,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward,
                          size: 12, color: AppColors.mutedText),
                    ),
                    Text(to,
                        style: AppTextStyles.caption
                            .copyWith(color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(vehicle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          if (eta != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ETA',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText, fontSize: 10)),
                Text(_fmtDate(eta),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy, fontWeight: FontWeight.w600)),
              ],
            ),
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

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
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
          Text(value,
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.navy, fontSize: 18)),
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

// ── Empty Section ──────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptySection({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.mutedText),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
