import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FerosSnackbar {
  FerosSnackbar._();

  static void success(String message) => _show(
    message: message,
    backgroundColor: AppColors.success,
    icon: Icons.check_circle_outline_rounded,
  );

  static void error(String message) => _show(
    message: message,
    backgroundColor: AppColors.error,
    icon: Icons.error_outline_rounded,
    duration: const Duration(seconds: 4),
  );

  static void warning(String message) => _show(
    message: message,
    backgroundColor: AppColors.warning,
    icon: Icons.warning_amber_rounded,
  );

  static void info(String message) => _show(
    message: message,
    backgroundColor: AppColors.info,
    icon: Icons.info_outline_rounded,
  );

  static void _show({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      messageText: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 10,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      isDismissible: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
