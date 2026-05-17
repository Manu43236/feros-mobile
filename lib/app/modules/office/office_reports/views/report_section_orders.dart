import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'report_widgets.dart';
import 'office_report_order_status.dart';
import 'office_report_fulfillment_rate.dart';
import 'office_report_lead_time.dart';
import 'office_report_unassigned_vehicles.dart';
import 'office_report_driver_assignments.dart';

class ReportSectionOrders extends StatelessWidget {
  const ReportSectionOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportSectionShell(
      title: 'Orders & Assignments',
      color: const Color(0xFF0284C7),
      icon: Icons.assignment_outlined,
      tiles: [
        ReportTile(
          icon: Icons.dashboard_outlined,
          label: 'Order Status',
          description: 'Order health overview — active, pending, completed',
          onTap: () => Get.to(() => const OfficeReportOrderStatus()),
        ),
        ReportTile(
          icon: Icons.check_circle_outline,
          label: 'Fulfillment Rate',
          description: 'Orders completed on time vs delayed or cancelled',
          onTap: () => Get.to(() => const OfficeReportFulfillmentRate()),
        ),
        ReportTile(
          icon: Icons.hourglass_top_outlined,
          label: 'Lead Time',
          description: 'Average days from order creation to completion',
          onTap: () => Get.to(() => const OfficeReportLeadTime()),
        ),
        ReportTile(
          icon: Icons.local_shipping_outlined,
          label: 'Unassigned Vehicles',
          description: 'Vehicles with no active order assigned right now',
          onTap: () => Get.to(() => const OfficeReportUnassignedVehicles()),
        ),
        ReportTile(
          icon: Icons.people_alt_outlined,
          label: 'Driver Assignments',
          description: 'How many trips each driver was assigned in period',
          onTap: () => Get.to(() => const OfficeReportDriverAssignments()),
        ),
      ],
    );
  }
}
