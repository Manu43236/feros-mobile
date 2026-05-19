import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import 'report_widgets.dart';
import 'office_report_driver_trips.dart';
import 'office_report_attendance_gaps.dart';
import 'office_report_attendance_trend.dart';
class ReportSectionDriverStaff extends StatelessWidget {
  const ReportSectionDriverStaff({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportSectionShell(
      title: 'Driver & Staff',
      color: AppColors.orange,
      icon: Icons.people_outline,
      tiles: [
        ReportTile(
          icon: Icons.emoji_events_outlined,
          label: 'Driver Trips',
          description: 'Trips, loaded and delivered tons per driver for period',
          onTap: () => Get.to(() => const OfficeReportDriverTrips()),
        ),
        ReportTile(
          icon: Icons.person_remove_outlined,
          label: 'Attendance Gaps',
          description: 'Staff with unmarked attendance days in period',
          onTap: () => Get.to(() => const OfficeReportAttendanceGaps()),
        ),
        ReportTile(
          icon: Icons.trending_up_outlined,
          label: 'Attendance Trend',
          description: 'Daily team attendance breakdown for selected period',
          onTap: () => Get.to(() => const OfficeReportAttendanceTrend()),
        ),
      ],
    );
  }
}
