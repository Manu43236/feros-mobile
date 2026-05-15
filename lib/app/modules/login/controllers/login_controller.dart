import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/validators.dart';

class LoginController extends GetxController {
  final _api  = Get.find<ApiClient>();
  final _auth = Get.find<AuthService>();

  final isLoading  = false.obs;
  final phoneError = RxnString();
  final pinError   = RxnString();

  Future<void> login({required String phone, required String pin}) async {
    final phoneVal = FerosValidators.phone(phone);
    if (phoneVal != null) {
      phoneError.value = phoneVal;
      return;
    }
    if (pin.length < 4) {
      pinError.value = 'Enter your 4-digit PIN';
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post(ApiEndpoints.login, data: {
        'phone': phone,
        'pin':   pin,
      });

      final data    = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>;
      final token   = payload['token'] as String;
      final user    = UserModel.fromJson(payload);

      await _auth.saveSession(token, user);
      Get.offAllNamed(_auth.roleHome);
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
