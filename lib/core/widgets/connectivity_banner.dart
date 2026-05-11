import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();
    return Column(
      children: [
        Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: connectivity.isOnline.value ? 0 : 36,
          color: AppColors.error,
          child: connectivity.isOnline.value
              ? const SizedBox.shrink()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text('No internet connection',
                      style: AppTextStyles.captionMedium.copyWith(color: Colors.white)),
                  ],
                ),
        )),
        Expanded(child: child),
      ],
    );
  }
}
