import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import 'report_widgets.dart';
import 'office_report_daily_activity.dart';
import 'office_report_local_long_trips.dart';
import 'office_report_idle_drivers.dart';
import 'office_report_doc_expiry.dart';
import 'office_report_today_attendance.dart';
import 'office_report_delayed_trips.dart';
import 'office_report_orders_backlog.dart';

class ReportSectionDailyOps extends StatelessWidget {
  const ReportSectionDailyOps({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportSectionShell(
      title: 'Daily Operations',
      color: AppColors.navy,
      icon: Icons.today_outlined,
      tiles: [
        ReportTile(
          icon: Icons.directions_bus_outlined,
          label: 'Fleet Activity',
          description: 'Live vehicle snapshot — where every vehicle is today',
          onTap: () => Get.to(() => const OfficeReportDailyActivity()),
        ),
        ReportTile(
          icon: Icons.route_outlined,
          label: 'Local vs Long Trips',
          description: 'Split of local-haul and long-distance trips today',
          onTap: () => Get.to(() => const OfficeReportLocalLongTrips()),
        ),
        ReportTile(
          icon: Icons.person_off_outlined,
          label: 'Idle Drivers',
          description: 'Drivers currently unassigned and available',
          onTap: () => Get.to(() => const OfficeReportIdleDrivers()),
        ),
        ReportTile(
          icon: Icons.warning_amber_outlined,
          label: 'Document Expiry',
          description: 'Vehicles & staff with expiring documents in next 30–90 days',
          onTap: () => Get.to(() => const OfficeReportDocExpiry()),
        ),
        ReportTile(
          icon: Icons.how_to_reg_outlined,
          label: "Today's Attendance",
          description: "Who marked present today across all roles",
          onTap: () => Get.to(() => const OfficeReportTodayAttendance()),
        ),
        ReportTile(
          icon: Icons.timer_off_outlined,
          label: 'Delayed Trips',
          description: 'Active trips running behind schedule',
          onTap: () => Get.to(() => const OfficeReportDelayedTrips()),
        ),
        ReportTile(
          icon: Icons.inbox_outlined,
          label: 'Orders Backlog',
          description: 'Open orders not yet assigned to a vehicle',
          onTap: () => Get.to(() => const OfficeReportOrdersBacklog()),
        ),
      ],
    );
  }
}
