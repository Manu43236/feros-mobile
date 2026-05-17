import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'report_widgets.dart';
import 'office_report_lr_register.dart';
import 'office_report_trips_in_progress.dart';
import 'office_report_lr_funnel.dart';
import 'office_report_unbilled_lrs.dart';
import 'office_report_invoice_turnaround.dart';
import 'office_report_trip_duration.dart';
import 'office_report_weight_variance.dart';
import 'office_report_overloading.dart';

class ReportSectionLrs extends StatelessWidget {
  const ReportSectionLrs({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportSectionShell(
      title: 'Trips & LRs',
      color: const Color(0xFF7C3AED),
      icon: Icons.receipt_long_outlined,
      tiles: [
        ReportTile(
          icon: Icons.receipt_long_outlined,
          label: 'LR Register',
          description: 'All lorry receipts — filter by status, search by LR#',
          onTap: () => Get.to(() => const OfficeReportLrRegister()),
        ),
        ReportTile(
          icon: Icons.local_shipping_outlined,
          label: 'Trips In Progress',
          description: 'All LRs currently in transit with live status',
          onTap: () => Get.to(() => const OfficeReportTripsInProgress()),
        ),
        ReportTile(
          icon: Icons.filter_alt_outlined,
          label: 'LR Status Funnel',
          description: 'How LRs move from created → delivered → billed',
          onTap: () => Get.to(() => const OfficeReportLrFunnel()),
        ),
        ReportTile(
          icon: Icons.pending_actions_outlined,
          label: 'Unbilled LRs',
          description: 'Delivered LRs not yet converted to an invoice',
          onTap: () => Get.to(() => const OfficeReportUnbilledLrs()),
        ),
        ReportTile(
          icon: Icons.timer_outlined,
          label: 'Invoice Turnaround',
          description: 'Days from LR delivery to invoice generation',
          onTap: () => Get.to(() => const OfficeReportInvoiceTurnaround()),
        ),
        ReportTile(
          icon: Icons.schedule_outlined,
          label: 'Trip Duration',
          description: 'Average trip duration per route in selected period',
          onTap: () => Get.to(() => const OfficeReportTripDuration()),
        ),
        ReportTile(
          icon: Icons.scale_outlined,
          label: 'Weight Variance',
          description: 'Actual weight vs billed weight across LRs',
          onTap: () => Get.to(() => const OfficeReportWeightVariance()),
        ),
        ReportTile(
          icon: Icons.warning_outlined,
          label: 'Overloading',
          description: 'LRs where actual weight exceeded vehicle capacity',
          onTap: () => Get.to(() => const OfficeReportOverloading()),
        ),
      ],
    );
  }
}
