import 'dart:async';
import 'dart:io';
import 'package:feros/core/services/storage_service.dart';
import 'package:feros/core/utils/env_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  final isLoading    = false.obs;
  final phoneError   = RxnString();
  final pinError     = RxnString();
  final lockedUntil   = Rxn<DateTime>();
  final secondsLeft   = 0.obs;
  final isAskingAdmin = false.obs;
  final attemptsUsed  = 0.obs;

  Timer? _lockTimer;
  late final StorageService _storage;

  bool get isLocked => lockedUntil.value != null && secondsLeft.value > 0;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _restoreStoredLockout();
  }

  Future<void> _restoreStoredLockout() async {
    final until = await _storage.getLockout();
    if (until == null) return;
    if (until.isAfter(DateTime.now())) {
      _startLockTimer(until);
    } else {
      await _storage.clearLockout();
    }
  }

  String get _pin => pinControllers.map((c) => c.text).join();

  @override
  void onClose() {
    _lockTimer?.cancel();
    phoneController.dispose();
    for (final c in pinControllers) c.dispose();
    for (final f in pinFocusNodes)  f.dispose();
    super.onClose();
  }

  void _startLockTimer(DateTime until) {
    lockedUntil.value = until;
    _updateSecondsLeft();
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsLeft();
    });
  }

  void _updateSecondsLeft() {
    final diff = lockedUntil.value!.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      secondsLeft.value = 0;
      lockedUntil.value = null;
      _lockTimer?.cancel();
      _storage.clearLockout();
    } else {
      secondsLeft.value = diff;
    }
  }

  Future<void> askPinReset() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) return;
    isAskingAdmin.value = true;
    try {
      await _api.post(ApiEndpoints.askPinReset(phone));
      FerosSnackbar.success('Request sent! Your admin has been notified.');
    } catch (_) {
      FerosSnackbar.error('Could not send request. Please try again.');
    } finally {
      if (!isClosed) isAskingAdmin.value = false;
    }
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
      String? fcmToken;
      if (EnvConfig.isProd) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      final response = await _api.post(ApiEndpoints.login, data: {
        'phone':      phoneController.text.trim(),
        'pin':        _pin,
        'deviceType': 'MOBILE',
        'deviceInfo': Platform.isAndroid ? 'Android' : 'iOS',
        'appVersion': packageInfo.version,
        if (fcmToken != null) 'fcmToken': fcmToken,
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
        if (EnvConfig.isProd) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseMessaging.instance.requestPermission();
          });
        }
      }
    } on AccountLockedException catch (e) {
      _startLockTimer(e.lockedUntil);
      _storage.saveLockout(e.lockedUntil);
      attemptsUsed.value = 0;
    } on WrongPinException catch (e) {
      attemptsUsed.value = e.failedAttempts;
      FerosSnackbar.error('Invalid phone number or PIN');
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
