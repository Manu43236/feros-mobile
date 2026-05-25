import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final phoneController = TextEditingController();
  final List<TextEditingController> pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> pinFocusNodes =
      List.generate(4, (_) => FocusNode());

  final isLoading  = false.obs;
  final phoneError = RxnString();
  final pinError   = RxnString();

  String get _pin => pinControllers.map((c) => c.text).join();

  @override
  void onClose() {
    phoneController.dispose();
    for (final c in pinControllers) c.dispose();
    for (final f in pinFocusNodes)  f.dispose();
    super.onClose();
  }

  void onPinDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) pinFocusNodes[index + 1].requestFocus();
    if (value.isEmpty   && index > 0)  pinFocusNodes[index - 1].requestFocus();
    pinError.value = null;
  }

  void onPhoneChanged(String _) => phoneError.value = null;

  Future<void> login() async {
    final phoneVal = FerosValidators.phone(phoneController.text.trim());
    if (phoneVal != null) { phoneError.value = phoneVal; return; }
    if (_pin.length < 4)  { pinError.value = 'Enter your 4-digit PIN'; return; }

    isLoading.value = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _api.post(ApiEndpoints.login, data: {
        'phone':      phoneController.text.trim(),
        'pin':        _pin,
        'deviceType': 'MOBILE',
        'deviceInfo': Platform.isAndroid ? 'Android' : 'iOS',
        'appVersion': packageInfo.version,
      });

      final data    = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>;
      final token   = payload['token'] as String;
      final user    = UserModel.fromJson(payload);

      if (user.role == 'SUPER_ADMIN') {
        FerosSnackbar.error('Super Admin cannot log in on the mobile app.');
        return;
      }

      await _auth.saveSession(token, user);
      if (user.isPinResetRequired) {
        Get.offAllNamed(Routes.FORCE_PIN_CHANGE);
      } else {
        Get.offAllNamed(_auth.roleHome);
      }
    } on UnauthorizedException {
      FerosSnackbar.error('Invalid phone number or PIN');
    } on PaymentRequiredException {
      FerosSnackbar.warning('Subscription expired. Contact your administrator.');
    } on NetworkException {
      FerosSnackbar.error('No internet connection');
    } on AppException catch (e) {
      FerosSnackbar.error(e.message);
    } catch (e) {
      FerosSnackbar.error('Something went wrong. Please try again.');
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}
