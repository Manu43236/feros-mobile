import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final ChipType type;

  const StatusChip({super.key, required this.status, this.type = ChipType.auto});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label,
        style: AppTextStyles.captionSemiBold.copyWith(color: fg)),
    );
  }

  (String label, Color bg, Color fg) _resolve(String s) {
    switch (s.toUpperCase()) {
      // LR
      case 'CREATED':     return ('Created',     AppColors.infoLight,    AppColors.info);
      case 'LOADED':      return ('Loaded',      const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
      case 'IN_TRANSIT':  return ('In Transit',  const Color(0xFFFFF7ED), AppColors.orange);
      case 'DELIVERED':   return ('Delivered',   AppColors.successLight, AppColors.success);
      case 'INVOICED':    return ('Invoiced',    const Color(0xFFF8FAFC), AppColors.mutedText);
      // Order
      case 'PENDING':     return ('Pending',     AppColors.warningLight, AppColors.warning);
      case 'ACTIVE':      return ('Active',      AppColors.infoLight,    AppColors.info);
      case 'COMPLETED':   return ('Completed',   AppColors.successLight, AppColors.success);
      case 'CANCELLED':   return ('Cancelled',   AppColors.errorLight,   AppColors.error);
      // Service
      case 'OPEN':        return ('Open',        AppColors.infoLight,    AppColors.info);
      case 'IN_PROGRESS': return ('In Progress', AppColors.warningLight, AppColors.warning);
      case 'OVERDUE':     return ('Overdue',     AppColors.errorLight,   AppColors.error);
      case 'DUE_SOON':    return ('Due Soon',    AppColors.warningLight, AppColors.warning);
      // Invoice
      case 'DRAFT':       return ('Draft',       const Color(0xFFF8FAFC), AppColors.mutedText);
      case 'SENT':        return ('Sent',        AppColors.infoLight,    AppColors.info);
      case 'PARTIALLY_PAID': return ('Part Paid', AppColors.warningLight, AppColors.warning);
      case 'PAID':        return ('Paid',        AppColors.successLight, AppColors.success);
      // Attendance
      case 'PRESENT':     return ('Present',     AppColors.successLight, AppColors.success);
      case 'ABSENT':      return ('Absent',      AppColors.errorLight,   AppColors.error);
      case 'HALF_DAY':    return ('Half Day',    AppColors.warningLight, AppColors.warning);
      case 'LEAVE':       return ('Leave',       AppColors.infoLight,    AppColors.info);
      case 'HOLIDAY':     return ('Holiday',     const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
      // Allocation
      case 'ALLOCATED':   return ('Allocated',   AppColors.infoLight,    AppColors.info);
      case 'LOADED':      return ('Loaded',      const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
      // Parts
      case 'REQUESTED':   return ('Requested',   AppColors.warningLight, AppColors.warning);
      case 'APPROVED':    return ('Approved',    AppColors.successLight, AppColors.success);
      case 'REJECTED':    return ('Rejected',    AppColors.errorLight,   AppColors.error);
      // Payroll
      case 'GENERATED':   return ('Generated',   AppColors.infoLight,    AppColors.info);
      case 'APPROVED':    return ('Approved',    AppColors.successLight, AppColors.success);
      case 'PAID':        return ('Paid',        AppColors.successLight, AppColors.success);
      // Default
      default:
        return (s, const Color(0xFFF1F5F9), AppColors.mutedText);
    }
  }
}

enum ChipType { auto, lr, order, service, invoice, attendance }
