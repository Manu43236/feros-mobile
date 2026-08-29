import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../controllers/supervisor_payslip_controller.dart';

class SupervisorPayslipView extends GetView<SupervisorPayslipController> {
  final bool showAppBar;
  const SupervisorPayslipView({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar ? AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text('lbl_payslip_title'.tr,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ) : null,
      body: controller.isLoading.value
          ? const ShimmerList(count: 4)
          : RefreshIndicator(
              onRefresh: controller.fetch,
              color: AppColors.navy,
              child: controller.payslips.isEmpty
                  ? EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'lbl_no_payslips'.tr,
                      subtitle: 'lbl_payslips_appear'.tr,
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
  bool _pdfLoading = false;

  Future<void> _viewPayslipPdf() async {
    final id = (widget.payslip['id'] as num?)?.toInt();
    if (id == null || _pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      final api   = Get.find<ApiClient>();
      final bytes = await api.getBytes(ApiEndpoints.payslipPdf(id));
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/payslip_$id.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {'file': file, 'title': 'Payslip', 'subtitle': ''},
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('Could not load payslip PDF');
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

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
                      Text('$presentDays / $totalDays ${'lbl_days_present'.tr}',
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
              _row('lbl_gross_pay'.tr, '₹${grossPay.toStringAsFixed(2)}'),
              _row('lbl_deductions_label'.tr, '- ₹${totalDeductions.toStringAsFixed(2)}'),
              if (advanceDeductions > 0)
                _row('lbl_advance_recovery'.tr,
                    '- ₹${advanceDeductions.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _row('lbl_net_pay'.tr, '₹${netPay.toStringAsFixed(2)}', bold: true),
            ],
            if (status == 'PAID') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pdfLoading ? null : _viewPayslipPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _pdfLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(
                    _pdfLoading ? 'Loading…' : 'View Payslip',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
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
