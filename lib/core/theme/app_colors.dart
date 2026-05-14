import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const navy       = Color(0xFF1E3A5F);
  static const orange     = Color(0xFFF97316);
  static const sidebarBg  = Color(0xFF0F2137);

  // Background
  static const background = Color(0xFFF1F5F9);
  static const surface    = Color(0xFFFFFFFF);

  // Border
  static const border     = Color(0xFFE2E8F0);
  static const borderFocus= Color(0xFF1E3A5F);

  // Text
  static const bodyText   = Color(0xFF1E293B);
  static const mutedText  = Color(0xFF64748B);
  static const hintText   = Color(0xFF94A3B8);
  static const white      = Color(0xFFFFFFFF);

  // Semantic
  static const error      = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEF2F2);
  static const success    = Color(0xFF16A34A);
  static const successLight = Color(0xFFF0FDF4);
  static const warning    = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const info       = Color(0xFF2563EB);
  static const infoLight  = Color(0xFFEFF6FF);

  // Status chips — LR
  static const lrCreated    = Color(0xFF2563EB);
  static const lrLoaded     = Color(0xFF7C3AED);
  static const lrInTransit  = Color(0xFFF97316);
  static const lrDelivered  = Color(0xFF16A34A);
  static const lrInvoiced   = Color(0xFF64748B);

  // Status chips — Order
  static const orderPending   = Color(0xFFF59E0B);
  static const orderActive    = Color(0xFF2563EB);
  static const orderCompleted = Color(0xFF16A34A);
  static const orderCancelled = Color(0xFFDC2626);

  // Status chips — Service
  static const serviceOpen       = Color(0xFF2563EB);
  static const serviceInProgress = Color(0xFFF97316);
  static const serviceCompleted  = Color(0xFF16A34A);
  static const serviceOverdue    = Color(0xFFDC2626);
  static const serviceDueSoon    = Color(0xFFF59E0B);

  // Status chips — Attendance
  static const attPresent   = Color(0xFF16A34A); // green
  static const attAbsent    = Color(0xFFDC2626); // red
  static const attHalfDay   = Color(0xFFF59E0B); // amber
  static const attLeave     = Color(0xFF2563EB); // blue
  static const attHoliday   = Color(0xFF7C3AED); // purple
  static const attWeeklyOff = Color(0xFF64748B); // slate

  // Shimmer
  static const shimmerBase      = Color(0xFFE2E8F0);
  static const shimmerHighlight = Color(0xFFF8FAFC);
}
