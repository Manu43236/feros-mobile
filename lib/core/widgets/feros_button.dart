import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

enum FerosButtonVariant { primary, secondary, destructive, ghost }
enum FerosButtonSize { small, medium, large }

class FerosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FerosButtonVariant variant;
  final FerosButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const FerosButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FerosButtonVariant.primary,
    this.size = FerosButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      FerosButtonSize.small  => 36.0,
      FerosButtonSize.medium => 48.0,
      FerosButtonSize.large  => 54.0,
    };
    final fontSize = switch (size) {
      FerosButtonSize.small  => 13.0,
      FerosButtonSize.medium => 15.0,
      FerosButtonSize.large  => 16.0,
    };

    final (bgColor, fgColor, border) = switch (variant) {
      FerosButtonVariant.primary     => (AppColors.orange, AppColors.white, null as BorderSide?),
      FerosButtonVariant.secondary   => (AppColors.surface, AppColors.navy, const BorderSide(color: AppColors.navy)),
      FerosButtonVariant.destructive => (AppColors.error, AppColors.white, null),
      FerosButtonVariant.ghost       => (Colors.transparent, AppColors.navy, null),
    };

    Widget child = isLoading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2, color: fgColor),
                const SizedBox(width: 6),
              ],
              Text(label,
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: fontSize, color: fgColor,
                )),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          disabledBackgroundColor: bgColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            side: border ?? BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}
