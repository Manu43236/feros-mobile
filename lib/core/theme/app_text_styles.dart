import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Inter';

  static const heading1 = TextStyle(
    fontFamily: _font, fontSize: 24,
    fontWeight: FontWeight.w700, color: AppColors.bodyText,
  );
  static const heading2 = TextStyle(
    fontFamily: _font, fontSize: 20,
    fontWeight: FontWeight.w700, color: AppColors.bodyText,
  );
  static const heading3 = TextStyle(
    fontFamily: _font, fontSize: 18,
    fontWeight: FontWeight.w600, color: AppColors.bodyText,
  );
  static const heading4 = TextStyle(
    fontFamily: _font, fontSize: 16,
    fontWeight: FontWeight.w600, color: AppColors.bodyText,
  );
  static const body = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w400, color: AppColors.bodyText,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w500, color: AppColors.bodyText,
  );
  static const bodySemiBold = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w600, color: AppColors.bodyText,
  );
  static const bodyBold = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w700, color: AppColors.bodyText,
  );
  static const caption = TextStyle(
    fontFamily: _font, fontSize: 12,
    fontWeight: FontWeight.w400, color: AppColors.mutedText,
  );
  static const captionMedium = TextStyle(
    fontFamily: _font, fontSize: 12,
    fontWeight: FontWeight.w500, color: AppColors.mutedText,
  );
  static const captionSemiBold = TextStyle(
    fontFamily: _font, fontSize: 12,
    fontWeight: FontWeight.w600, color: AppColors.mutedText,
  );
  static const label = TextStyle(
    fontFamily: _font, fontSize: 13,
    fontWeight: FontWeight.w500, color: AppColors.bodyText,
  );
  static const hint = TextStyle(
    fontFamily: _font, fontSize: 14,
    fontWeight: FontWeight.w400, color: AppColors.hintText,
  );
  static const buttonText = TextStyle(
    fontFamily: _font, fontSize: 15,
    fontWeight: FontWeight.w600, color: AppColors.white,
  );
  static const buttonTextSmall = TextStyle(
    fontFamily: _font, fontSize: 13,
    fontWeight: FontWeight.w600, color: AppColors.white,
  );
  static const navLabel = TextStyle(
    fontFamily: _font, fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
