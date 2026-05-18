import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/office_dashboard_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../office_shell/controllers/office_shell_controller.dart';
import '../../office_finance/views/office_finance_view.dart';
import '../../office_attendance/views/office_attendance_view.dart';
import '../../office_staff/views/office_staff_view.dart';

class OfficeDashboardView extends StatelessWidget {
  final OfficeDashboardController controller;
  const OfficeDashboardView({super.key, required this.controller});

  void _goToTab(int index) =>
      Get.find<OfficeShellController>().onTabTapped(index);

  String _fmtRupee(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
      children: [

        // ── Stat Cards (2×2) ─────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Icons.assignment_outlined,
              iconColor: AppColors.navy,
              label: 'Active Orders',
              value: '${controller.orderTotal.value}',
              sub: '${controller.orderInTransit.value} in transit · ${controller.orderPending.value} pending',
              onTap: () => _goToTab(1),
            ),
            _StatCard(
              icon: Icons.local_shipping_outlined,
              iconColor: AppColors.orange,
              label: 'Fleet Size',
              value: '${controller.vehicleTotal.value}',
              sub: '${controller.vehicleOnTrip.value} on trip · ${controller.vehicleAvailable.value} available',
              onTap: () => _goToTab(2),
            ),
            _StatCard(
              icon: Icons.receipt_outlined,
              iconColor: AppColors.error,
              label: 'Outstanding',
              value: _fmtRupee(controller.invoiceOutstanding.value),
              sub: '${controller.invoiceOverdue.value} overdue invoices',
              onTap: () => Get.to(() => const OfficeFinanceView()),
            ),
            _StatCard(
              icon: Icons.people_outlined,
              iconColor: AppColors.success,
              label: "Today's Attendance",
              value: '${controller.attPresent.value}',
              sub: 'of ${controller.attTotal.value} staff · ${controller.attAbsent.value} absent',
              onTap: () => Get.to(() => const OfficeAttendanceView()),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Order Status ──────────────────────────────────────────────
        _SectionCard(
          icon: Icons.assignment_outlined,
          title: 'Order Status',
          accentColor: AppColors.navy,
          onTap: () => _goToTab(1),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusTile('Pending',       controller.orderPending.value,            const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                const SizedBox(width: 8),
                _StatusTile('Part. Assigned', controller.orderPartiallyAssigned.value, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                const SizedBox(width: 8),
                _StatusTile('Assigned',      controller.orderFullyAssigned.value,      const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                const SizedBox(width: 8),
                _StatusTile('In Transit',    controller.orderInTransit.value,          AppColors.orange,        const Color(0xFFFFF7ED)),
                const SizedBox(width: 8),
                _StatusTile('Part. Del.',    controller.orderPartiallyDelivered.value, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                const SizedBox(width: 8),
                _StatusTile('Delivered',     controller.orderDelivered.value,          AppColors.success,       const Color(0xFFF0FDF4)),
                const SizedBox(width: 8),
                _StatusTile('Cancelled',     controller.orderCancelled.value,          AppColors.error,         const Color(0xFFFEF2F2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Invoice Summary ───────────────────────────────────────────
        _SectionCard(
          icon: Icons.receipt_long_outlined,
          title: 'Invoice Summary',
          accentColor: const Color(0xFF0284C7),
          onTap: () => Get.to(() => const OfficeFinanceView()),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusTile('Draft',       controller.invoiceDraft.value,         AppColors.mutedText,     const Color(0xFFF8FAFC)),
                const SizedBox(width: 8),
                _StatusTile('Sent',        controller.invoiceSent.value,          const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                const SizedBox(width: 8),
                _StatusTile('Part. Paid',  controller.invoicePartiallyPaid.value, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                const SizedBox(width: 8),
                _StatusTile('Overdue',     controller.invoiceOverdue.value,       AppColors.error,         const Color(0xFFFEF2F2)),
                const SizedBox(width: 8),
                _StatusTile('Paid',        controller.invoicePaid.value,          AppColors.success,       const Color(0xFFF0FDF4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Vehicle Expiry Alerts ─────────────────────────────────────
        _AlertSection(
          icon: Icons.local_shipping_outlined,
          title: 'Vehicle Document Alerts',
          count: controller.vehicleAlerts.length,
          emptyText: 'All vehicle documents up to date',
          items: controller.vehicleAlerts,
          onTap: () => _goToTab(2),
          labelBuilder: (item) => item['registrationNumber'] as String? ?? '—',
          subBuilder: (item) => item['alertType'] as String? ?? '',
          dateBuilder: (item) => item['expiryDate'] as String? ?? '',
          daysLeftBuilder: (item) => (item['daysLeft'] as num?)?.toInt() ?? 0,
          expiredBuilder: (item) => item['expired'] as bool? ?? false,
        ),
        const SizedBox(height: 14),

        // ── Staff Expiry Alerts ───────────────────────────────────────
        _AlertSection(
          icon: Icons.badge_outlined,
          title: 'Staff Document Alerts',
          count: controller.staffAlerts.length,
          emptyText: 'All staff documents up to date',
          items: controller.staffAlerts,
          onTap: () => Get.to(() => const OfficeStaffView()),
          labelBuilder: (item) => item['userName'] as String? ?? '—',
          subBuilder: (item) => item['documentType'] as String? ?? '',
          dateBuilder: (item) => item['expiryDate'] as String? ?? '',
          daysLeftBuilder: (item) => (item['daysLeft'] as num?)?.toInt() ?? 0,
          expiredBuilder: (item) => item['expired'] as bool? ?? false,
        ),
        const SizedBox(height: 14),

        // ── Today's Snapshot ─────────────────────────────────────────
        GestureDetector(
          onTap: () => Get.to(() => const OfficeAttendanceView()),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Text("Today's Snapshot",
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7))),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 16,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _SnapshotStat('Present',  controller.attPresent.value,  AppColors.success),
                    const SizedBox(width: 20),
                    _SnapshotStat('Absent',   controller.attAbsent.value,   AppColors.error),
                    const SizedBox(width: 20),
                    _SnapshotStat('Half Day', controller.attHalfDay.value,  AppColors.warning),
                    const SizedBox(width: 20),
                    _SnapshotStat('On Leave', controller.attOnLeave.value,  AppColors.info),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
            color: AppColors.surface,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bodyText,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Status Tile ───────────────────────────────────────────────────────────────
class _StatusTile extends StatelessWidget {
  final String label;
  final int value;
  final Color textColor;
  final Color bgColor;
  const _StatusTile(this.label, this.value, this.textColor, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: textColor.withValues(alpha: 0.8), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Alert Section ─────────────────────────────────────────────────────────────
class _AlertSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final String emptyText;
  final List<Map<String, dynamic>> items;
  final VoidCallback onTap;
  final String Function(Map<String, dynamic>) labelBuilder;
  final String Function(Map<String, dynamic>) subBuilder;
  final String Function(Map<String, dynamic>) dateBuilder;
  final int Function(Map<String, dynamic>) daysLeftBuilder;
  final bool Function(Map<String, dynamic>) expiredBuilder;

  const _AlertSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.items,
    required this.onTap,
    required this.labelBuilder,
    required this.subBuilder,
    required this.dateBuilder,
    required this.daysLeftBuilder,
    required this.expiredBuilder,
  });

  Color _badgeColor(int days, bool expired) {
    if (expired)  return AppColors.error;
    if (days <= 7) return AppColors.orange;
    return AppColors.warning;
  }

  String _badgeText(int days, bool expired) {
    if (expired)    return 'Expired';
    if (days == 0)  return 'Today';
    return '${days}d left';
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: AppColors.orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600)),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(emptyText,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText)),
                ],
              ),
            )
          else
            ...items.take(5).map((item) {
              final days    = daysLeftBuilder(item);
              final expired = expiredBuilder(item);
              final color   = _badgeColor(days, expired);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labelBuilder(item),
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(subBuilder(item),
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_fmtDate(dateBuilder(item)),
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText, fontSize: 10)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(_badgeText(days, expired),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Snapshot Stat ─────────────────────────────────────────────────────────────
class _SnapshotStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SnapshotStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }
}
