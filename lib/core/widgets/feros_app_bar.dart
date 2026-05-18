import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FerosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final VoidCallback? onBack;

  const FerosAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.sidebarBg,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.sidebarBg,
        statusBarIconBrightness: Brightness.light,
      ),
      automaticallyImplyLeading: false,
      leading:
          leading ??
          (showBack
              ? GestureDetector(
                  onTap: onBack ?? Get.back,
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.white,
                    size: 18,
                  ),
                )
              : null),
      title: Text(
        title,
        style: AppTextStyles.heading4.copyWith(color: AppColors.white),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
