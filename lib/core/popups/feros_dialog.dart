import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/feros_button.dart';

class FerosDialog {
  FerosDialog._();

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(title, style: AppTextStyles.heading4),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedText)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDestructive ? AppColors.error : AppColors.navy,
              )),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> info({
    required String title,
    required String message,
  }) async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(title, style: AppTextStyles.heading4),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  static Future<T?> bottomSheet<T>({
    required String title,
    required Widget child,
    bool isScrollControlled = true,
  }) async {
    return await Get.bottomSheet<T>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
      isScrollControlled: isScrollControlled,
    );
  }
}
