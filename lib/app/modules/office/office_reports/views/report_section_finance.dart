import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import 'report_widgets.dart';
import 'office_report_outstanding.dart';
import 'office_report_collections.dart';
import 'office_report_revenue_trend.dart';
import 'office_report_invoice_aging.dart';
import 'office_report_route_profitability.dart';
import 'office_report_gst_summary.dart';
import 'office_report_credit_notes.dart';
import 'office_report_pending_billing.dart';

class ReportSectionFinance extends StatelessWidget {
  const ReportSectionFinance({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportSectionShell(
      title: 'Finance',
      color: AppColors.success,
      icon: Icons.account_balance_outlined,
      tiles: [
        ReportTile(
          icon: Icons.trending_up_outlined,
          label: 'Revenue Trend',
          description: '12-month revenue chart with month-over-month growth',
          onTap: () => Get.to(() => const OfficeReportRevenueTrend()),
        ),
        ReportTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Outstanding',
          description: 'What clients still owe — with aging analysis',
          onTap: () => Get.to(() => const OfficeReportOutstanding()),
        ),
        ReportTile(
          icon: Icons.payments_outlined,
          label: 'Collections',
          description: 'Payments received by mode and date range',
          onTap: () => Get.to(() => const OfficeReportCollections()),
        ),
        ReportTile(
          icon: Icons.layers_outlined,
          label: 'Invoice Aging',
          description: 'Overdue invoices bucketed by days outstanding',
          onTap: () => Get.to(() => const OfficeReportInvoiceAging()),
        ),
        ReportTile(
          icon: Icons.pending_actions_outlined,
          label: 'Pending Billing',
          description: 'Clients with delivered LRs not yet invoiced',
          onTap: () => Get.to(() => const OfficeReportPendingBilling()),
        ),
        ReportTile(
          icon: Icons.alt_route_outlined,
          label: 'Route Profitability',
          description: 'Revenue, cost, and margin per route',
          onTap: () => Get.to(() => const OfficeReportRouteProfitability()),
        ),
        ReportTile(
          icon: Icons.receipt_outlined,
          label: 'GST Summary',
          description: 'Tax collected and payable for period — HSN breakdown',
          onTap: () => Get.to(() => const OfficeReportGstSummary()),
        ),
        ReportTile(
          icon: Icons.discount_outlined,
          label: 'Credit Notes',
          description: 'Adjustments and credit notes issued to clients',
          onTap: () => Get.to(() => const OfficeReportCreditNotes()),
        ),
      ],
    );
  }
}
