import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../localization/locale_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Drop-in tile for any profile screen.
/// Shows current language and opens a bottom sheet to switch.
class LanguageSwitcherTile extends StatelessWidget {
  const LanguageSwitcherTile({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleService>();
    return Obx(() {
      final label = locale.isTelugu ? 'తెలుగు' : 'English';
      return ListTile(
        leading: const Icon(Icons.language, color: AppColors.navy, size: 22),
        title: Text(
          'lbl_language'.tr,
          style: AppTextStyles.body.copyWith(color: AppColors.navy),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
        onTap: () => _showLanguageSheet(context, locale),
      );
    });
  }

  void _showLanguageSheet(BuildContext context, LocaleService locale) {
    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Obx(() {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'lbl_select_language'.tr,
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LangOption(
                label: 'English',
                sublabel: 'English',
                selected: locale.isEnglish,
                onTap: () {
                  locale.setEnglish();
                  Get.back();
                },
              ),
              _LangOption(
                label: 'తెలుగు',
                sublabel: 'Telugu',
                selected: locale.isTelugu,
                onTap: () {
                  locale.setTelugu();
                  Get.back();
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: selected ? AppColors.navy : AppColors.bodyText,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(sublabel,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.navy, size: 22)
          : const Icon(Icons.circle_outlined,
              color: AppColors.mutedText, size: 22),
      onTap: onTap,
    );
  }
}
