import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/modules/driver/driver_shell/controllers/driver_shell_controller.dart';
import 'app/routes/app_pages.dart';
import 'core/localization/app_translations.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/widgets/stg_banner.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

String _currentRole() {
  try {
    return Get.find<AuthService>().user?.role ?? '';
  } catch (_) {
    return '';
  }
}

void _smTabSwitch(int index) {
  if (Get.isRegistered<DriverShellController>()) {
    Get.find<DriverShellController>().onTabTapped(index);
  }
}

void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] ?? '';
  final role = _currentRole();

  switch (type) {
    case 'NEW_ORDER':
      // Legacy order created notification — supervisor navigates to order detail
      final orderId = int.tryParse(data['orderId'] ?? '');
      if (orderId != null) Get.toNamed('/orders/detail', arguments: orderId);

    case 'BREAKDOWN':
      if (role == 'SUPERVISOR' && data['orderId'] != null) {
        final orderId = int.tryParse(data['orderId']!);
        if (orderId != null) Get.toNamed('/orders/detail', arguments: orderId);
      } else {
        _smTabSwitch(1); // SM: Services tab
      }

    case 'SERVICE_COMPLETE':
    case 'PART_REQUEST':
      _smTabSwitch(1); // SM: Services tab

    case 'TYRE_ALERT':
      _smTabSwitch(2); // SM: Tyres tab
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  if (!kDebugMode) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        Get.snackbar(
          n.title ?? '',
          n.body ?? '',
          duration: const Duration(seconds: 4),
        );
      }
    });

    // getInitialMessage hangs on iOS simulator — skip in debug
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar: light icons on dark background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FerosApp());
}

class FerosApp extends StatelessWidget {
  const FerosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FEROS',
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => StgBanner(child: child!),
    );
  }
}
