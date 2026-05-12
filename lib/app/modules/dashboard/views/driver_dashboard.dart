import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../payslip/views/payslip_view.dart';
import '../../shell/controllers/shell_controller.dart';
import '../controllers/dashboard_controller.dart';

class DriverDashboard extends StatefulWidget {
  final DashboardController controller;
  const DriverDashboard({super.key, required this.controller});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _dateRange = 'This Week';
  static const _ranges = ['Today', 'This Week', 'This Month', 'All'];

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((t) {
      final raw = t['expectedLoadDate'] as String?;
      if (raw == null) return _dateRange == 'All';
      final d = DateTime.tryParse(raw);
      if (d == null) return _dateRange == 'All';
      final day = DateTime(d.year, d.month, d.day);

      switch (_dateRange) {
        case 'Today':
          return day == today;
        case 'This Week':
          return !day.isBefore(today) &&
              day.isBefore(today.add(const Duration(days: 7)));
        case 'This Month':
          return d.year == now.year && d.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Stat Cards ─────────────────────────────────────────
        Obx(() => Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Trips',
                value: '${c.totalTrips.value}',
                icon: Icons.local_shipping_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Get.find<ShellController>().onTabTapped(2),
                child: _StatCard(
                  label: 'Attendance',
                  value: c.isAttendanceMarked.value ? 'Present ✓' : 'Tap to Mark',
                  icon: Icons.check_circle_outline,
                  borderColor: c.isAttendanceMarked.value
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                  valueColor: c.isAttendanceMarked.value
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${c.pendingTrips.value}',
                icon: Icons.pending_actions_outlined,
                borderColor: c.pendingTrips.value > 0
                    ? const Color(0xFFD97706)
                    : AppColors.navy,
                valueColor: c.pendingTrips.value > 0
                    ? const Color(0xFFD97706)
                    : null,
              ),
            ),
          ],
        )),
        const SizedBox(height: 24),

        // ── Upcoming Bookings ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Bookings',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            TextButton(
              onPressed: () => Get.find<ShellController>().onTabTapped(1),
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

        // ── Date Range Chips ───────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ranges.map((r) {
              final active = _dateRange == r;
              return GestureDetector(
                onTap: () => setState(() => _dateRange = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active ? AppColors.navy : AppColors.border),
                  ),
                  child: Text(r,
                      style: AppTextStyles.caption.copyWith(
                        color: active ? Colors.white : AppColors.mutedText,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── Booking List ───────────────────────────────────────
        Obx(() {
          final filtered = _filtered(c.upcomingTrips);
          if (filtered.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Center(
                child: Text('No bookings for $_dateRange',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ),
            );
          }
          return Column(
            children: filtered
                .map((t) => _BookingCard(trip: t))
                .toList(),
          );
        }),
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
                onTap: () => Get.find<ShellController>().onTabTapped(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.local_shipping_outlined,
                label: 'My\nTrips',
                onTap: () => Get.find<ShellController>().onTabTapped(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.payments_outlined,
                label: 'My\nPayroll',
                onTap: () => Get.to(() => const PayslipView()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _BookingCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final loadDate = trip['expectedLoadDate'] as String?;
    final deliveryDate = trip['expectedDeliveryDate'] as String?;
    final status = trip['lrStatus'] as String? ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'WEIGHT_LOADED':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'Ready to Start';
        break;
      case 'CREATED':
        statusColor = AppColors.navy;
        statusLabel = 'Scheduled';
        break;
      default:
        statusColor = AppColors.mutedText;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row + status
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(_formatDate(loadDate),
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              if (deliveryDate != null) ...[
                const Text('  →  ',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.mutedText)),
                Text(_formatDate(deliveryDate),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Client
          Text(trip['clientName']?.toString() ?? '—',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
          const SizedBox(height: 6),

          // Route
          Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  size: 11, color: AppColors.navy),
              const SizedBox(width: 4),
              Expanded(
                child: Text(trip['fromCity']?.toString() ?? '—',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward,
                    size: 11, color: AppColors.mutedText),
              ),
              const Icon(Icons.location_on_outlined,
                  size: 11, color: AppColors.navy),
              const SizedBox(width: 4),
              Expanded(
                child: Text(trip['toCity']?.toString() ?? '—',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vehicle
          Row(
            children: [
              const Icon(Icons.directions_bus_outlined,
                  size: 13, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(trip['vehicleNumber']?.toString() ?? '—',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedText)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]}';
    } catch (_) {
      return raw;
    }
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
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
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
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
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
