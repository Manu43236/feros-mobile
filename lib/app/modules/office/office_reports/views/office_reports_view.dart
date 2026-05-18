import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'report_section_daily_ops.dart';
import 'report_section_orders.dart';
import 'report_section_lrs.dart';
import 'report_section_driver_staff.dart';
import 'report_section_finance.dart';

class OfficeReportsView extends StatelessWidget {
  const OfficeReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Reports'),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionCard(
            icon: Icons.today_outlined,
            label: 'Daily Operations',
            description:
                'Fleet activity, idle drivers, document expiry, delays',
            reportCount: 7,
            color: AppColors.navy,
            onTap: () => Get.to(() => const ReportSectionDailyOps()),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.assignment_outlined,
            label: 'Orders & Assignments',
            description:
                'Order health, fulfillment rate, lead time, driver assignments',
            reportCount: 5,
            color: const Color(0xFF0284C7),
            onTap: () => Get.to(() => const ReportSectionOrders()),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.receipt_long_outlined,
            label: 'Trips & LRs',
            description:
                'LR register, trips in progress, unbilled LRs, weight variance',
            reportCount: 8,
            color: const Color(0xFF7C3AED),
            onTap: () => Get.to(() => const ReportSectionLrs()),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.people_outline,
            label: 'Driver & Staff',
            description:
                'Driver performance, attendance calendar, payroll summary',
            reportCount: 6,
            color: AppColors.orange,
            onTap: () => Get.to(() => const ReportSectionDriverStaff()),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.account_balance_outlined,
            label: 'Finance',
            description:
                'Revenue trend, outstanding, collections, GST, route profitability',
            reportCount: 8,
            color: const Color(0xFF059669),
            onTap: () => Get.to(() => const ReportSectionFinance()),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final int reportCount;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.reportCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$reportCount',
                            style: AppTextStyles.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
