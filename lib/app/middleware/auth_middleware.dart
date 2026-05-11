import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // currentUser is loaded from secure storage at startup in AuthService.onInit()
    // If null, the user hasn't logged in yet.
    final auth = Get.find<AuthService>();
    if (auth.currentUser.value == null) {
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}
