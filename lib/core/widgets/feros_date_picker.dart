import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../utils/date_utils.dart';

class FerosDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime) onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;

  const FerosDatePicker({
    super.key,
    required this.label,
    required this.onPicked,
    this.value,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.label,
            children: isRequired
                ? [const TextSpan(text: ' *', style: TextStyle(color: AppColors.error))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? FerosDateUtils.formatDate(value!.toIso8601String())
                        : 'Select date',
                    style: value != null
                        ? AppTextStyles.body
                        : AppTextStyles.hint,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.mutedText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
