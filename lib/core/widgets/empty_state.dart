import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'feros_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.border),
            const SizedBox(height: 16),
            Text(title,
              style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center),
            ],
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 20),
              FerosButton(label: buttonLabel!, onPressed: onButton, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FerosButton(
                label: 'Retry',
                onPressed: onRetry,
                fullWidth: false,
                variant: FerosButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
