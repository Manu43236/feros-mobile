import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool showDivider;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: AppTextStyles.caption),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: valueWidget ?? Text(
                  value ?? '—',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
            style: AppTextStyles.captionSemiBold.copyWith(
              color: AppColors.mutedText,
              letterSpacing: 0.5,
            ).copyWith(fontFamily: 'Inter')),
        ),
        if (action != null) action!,
      ],
    );
  }
}
