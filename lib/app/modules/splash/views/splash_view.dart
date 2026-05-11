import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../routes/app_pages.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    try {
      final storage = Get.find<StorageService>();
      final isLoggedIn = await storage.isLoggedIn();
      if (isLoggedIn) {
        final role = await storage.getRole();
        Get.offAllNamed(_roleHome(role));
      } else {
        Get.offAllNamed(Routes.LOGIN);
      }
    } catch (_) {
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  String _roleHome(String? role) {
    switch (role) {
      case 'ADMIN':        return Routes.DASHBOARD;
      case 'OFFICE_STAFF': return Routes.ORDERS;
      case 'SUPERVISOR':   return Routes.ORDERS;
      case 'DRIVER':
      case 'CLEANER':      return Routes.MY_TRIPS;
      case 'SERVICE_MEN':  return Routes.VEHICLE_SERVICES;
      case 'STORE_KEEPER': return Routes.INVENTORY;
      default:             return Routes.LOGIN;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.65,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'Powered by FEROS',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
