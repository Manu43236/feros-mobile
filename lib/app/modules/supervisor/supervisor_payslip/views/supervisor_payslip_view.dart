import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_payslip_controller.dart';

class SupervisorPayslipView extends GetView<SupervisorPayslipController> {
  const SupervisorPayslipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text('Payslip',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: controller.isLoading.value
          ? const ShimmerList(count: 4)
          : RefreshIndicator(
              onRefresh: controller.fetch,
              color: AppColors.navy,
              child: controller.payslips.isEmpty
                  ? const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No Payslips Yet',
                      subtitle: 'Your monthly payslips will appear here',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.payslips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _PayslipCard(payslip: controller.payslips[i]),
                    ),
            ),
    ));
  }
}

// ── Payslip Card ───────────────────────────────────────────────────────────────
class _PayslipCard extends StatefulWidget {
  final Map<String, dynamic> payslip;
  const _PayslipCard({required this.payslip});

  @override
  State<_PayslipCard> createState() => _PayslipCardState();
}

class _PayslipCardState extends State<_PayslipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p               = widget.payslip;
    final start           = p['payCycleStartDate'] as String? ?? '—';
    final end             = p['payCycleEndDate']   as String? ?? '—';
    final netPay          = (p['netPay']           as num?)?.toDouble() ?? 0;
    final status          = p['status']            as String? ?? '—';
    final presentDays     = p['presentDays']       as int?    ?? 0;
    final totalDays       = p['totalDays']         as int?    ?? 0;
    final grossPay        = (p['grossPay']         as num?)?.toDouble() ?? 0;
    final totalDeductions = (p['totalDeductions']  as num?)?.toDouble() ?? 0;
    final advanceDeductions = (p['advanceDeductions'] as num?)?.toDouble() ?? 0;

    final statusColor = status == 'APPROVED'
        ? const Color(0xFF16A34A)
        : status == 'GENERATED'
            ? const Color(0xFFD97706)
            : AppColors.mutedText;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$start  →  $end',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.navy)),
                      const SizedBox(height: 2),
                      Text('$presentDays / $totalDays days present',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${netPay.toStringAsFixed(0)}',
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.navy)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: AppTextStyles.caption
                              .copyWith(color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _row('Gross Pay', '₹${grossPay.toStringAsFixed(2)}'),
              _row('Deductions', '- ₹${totalDeductions.toStringAsFixed(2)}'),
              if (advanceDeductions > 0)
                _row('Advance Recovery',
                    '- ₹${advanceDeductions.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _row('Net Pay', '₹${netPay.toStringAsFixed(2)}', bold: true),
            ],
            const SizedBox(height: 4),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          Text(value,
              style: bold
                  ? AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)
                  : AppTextStyles.caption.copyWith(color: AppColors.navy)),
        ],
      ),
    );
  }
}
