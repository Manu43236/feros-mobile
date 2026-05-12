import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_controller.dart';

class SupervisorDashboard extends StatelessWidget {
  final DashboardController controller;
  const SupervisorDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Stat Cards ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Orders',
                value: '—',
                icon: Icons.assignment_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'In Transit',
                value: '—',
                icon: Icons.local_shipping_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Staff Today',
                value: '—',
                icon: Icons.group_outlined,
                borderColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Quick Actions ──────────────────────────────────────────
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                label: 'Orders',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'LRs',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.check_circle_outline,
                label: 'Attendance',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Coming Soon Notice ─────────────────────────────────────
        _ComingSoonCard(
          title: 'Supervisor Features',
          subtitle: 'Order management, LR creation, staff attendance marking and more are coming in Sprint 3.',
        ),
      ],
    );
  }
}

// ── Office Staff Dashboard ─────────────────────────────────────────────────────
class OfficeDashboard extends StatelessWidget {
  final DashboardController controller;
  const OfficeDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Orders',
                value: '—',
                icon: Icons.assignment_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pending LRs',
                value: '—',
                icon: Icons.receipt_long_outlined,
                borderColor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Invoices Due',
                value: '—',
                icon: Icons.payments_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                label: 'Orders',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'LRs',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.payments_outlined,
                label: 'Invoices',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ComingSoonCard(
          title: 'Office Staff Features',
          subtitle: 'Orders, LRs, invoices, clients and payroll management are coming in Sprint 5.',
        ),
      ],
    );
  }
}

// ── Service Men Dashboard ──────────────────────────────────────────────────────
class ServiceMenDashboard extends StatelessWidget {
  final DashboardController controller;
  const ServiceMenDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Services',
                value: '—',
                icon: Icons.build_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Parts Requested',
                value: '—',
                icon: Icons.inventory_2_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Completed',
                value: '—',
                icon: Icons.check_circle_outline,
                borderColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.build_outlined,
                label: 'My Services',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_box_outlined,
                label: 'Request Part',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.car_crash_outlined,
                label: 'Breakdown',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ComingSoonCard(
          title: 'Service Men Features',
          subtitle: 'Vehicle services, spare part requests and breakdown reporting are coming in Sprint 4.',
        ),
      ],
    );
  }
}

// ── Store Keeper Dashboard ─────────────────────────────────────────────────────
class StoreKeeperDashboard extends StatelessWidget {
  final DashboardController controller;
  const StoreKeeperDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pending Requests',
                value: '—',
                icon: Icons.list_alt_outlined,
                borderColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Low Stock',
                value: '—',
                icon: Icons.warning_amber_outlined,
                borderColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Parts',
                value: '—',
                icon: Icons.inventory_2_outlined,
                borderColor: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.list_alt_outlined,
                label: 'Part\nRequests',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_box_outlined,
                label: 'Stock\nIn',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ComingSoonCard(
          title: 'Store Keeper Features',
          subtitle: 'Part requests approval, stock management and inventory tracking are coming in Sprint 4.',
        ),
      ],
    );
  }
}

// ── Admin Dashboard ────────────────────────────────────────────────────────────
class AdminDashboard extends StatelessWidget {
  final DashboardController controller;
  const AdminDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Vehicles',
                value: '—',
                icon: Icons.directions_bus_outlined,
                borderColor: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Active Orders',
                value: '—',
                icon: Icons.assignment_outlined,
                borderColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Staff',
                value: '—',
                icon: Icons.group_outlined,
                borderColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Actions',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _QuickAction(icon: Icons.directions_bus_outlined, label: 'Vehicles',  onTap: () {}),
            _QuickAction(icon: Icons.assignment_outlined,     label: 'Orders',    onTap: () {}),
            _QuickAction(icon: Icons.receipt_long_outlined,   label: 'LRs',       onTap: () {}),
            _QuickAction(icon: Icons.group_outlined,          label: 'Staff',     onTap: () {}),
            _QuickAction(icon: Icons.payments_outlined,       label: 'Invoices',  onTap: () {}),
            _QuickAction(icon: Icons.bar_chart_outlined,      label: 'Reports',   onTap: () {}),
          ],
        ),
        const SizedBox(height: 24),
        _ComingSoonCard(
          title: 'Admin Features',
          subtitle: 'Full platform management — vehicles, orders, staff, invoices, reports and more — coming in Sprints 6, 7 and 8.',
        ),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────
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
                  .copyWith(color: AppColors.navy, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

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
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ComingSoonCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
