import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import 'report_widgets.dart';
import 'office_report_attendance.dart';
import 'office_report_payroll.dart';
import 'office_report_driver_trips.dart';
import 'office_report_attendance_gaps.dart';
import 'office_report_attendance_trend.dart';
import 'office_report_attendance_calendar.dart';

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
          label: 'Driver Performance',
          description: 'Trips, km, and on-time rate per driver for period',
          onTap: () => Get.to(() => const OfficeReportDriverTrips()),
        ),
        ReportTile(
          icon: Icons.fact_check_outlined,
          label: 'Attendance',
          description: 'Daily attendance records filtered by date range',
          onTap: () => Get.to(() => const OfficeReportAttendance()),
        ),
        ReportTile(
          icon: Icons.calendar_month_outlined,
          label: 'Attendance Calendar',
          description: 'Monthly grid view of presence/absence per staff',
          onTap: () => Get.to(() => const OfficeReportAttendanceCalendar()),
        ),
        ReportTile(
          icon: Icons.trending_up_outlined,
          label: 'Attendance Trend',
          description: 'Team attendance % week by week',
          onTap: () => Get.to(() => const OfficeReportAttendanceTrend()),
        ),
        ReportTile(
          icon: Icons.person_remove_outlined,
          label: 'Attendance Gaps',
          description: 'Staff with consecutive absences or low attendance',
          onTap: () => Get.to(() => const OfficeReportAttendanceGaps()),
        ),
        ReportTile(
          icon: Icons.savings_outlined,
          label: 'Payroll',
          description: 'Staff cost summary for selected month',
          onTap: () => Get.to(() => const OfficeReportPayroll()),
        ),
      ],
    );
  }
}
