import 'package:get/get.dart';
import 'view_state.dart';
import '../exceptions/app_exception.dart';
import '../exceptions/exception_handler.dart';
import '../popups/feros_snackbar.dart';

abstract class BaseController extends GetxController {
  final state    = ViewState.initial.obs;
  final errorMsg = ''.obs;

  bool get isLoading => state.value == ViewState.loading;
  bool get hasError  => state.value == ViewState.error;
  bool get isEmpty   => state.value == ViewState.empty;
  bool get isSuccess => state.value == ViewState.success;

  void setLoading() => state.value = ViewState.loading;
  void setError(String msg) {
    errorMsg.value = msg;
    state.value = ViewState.error;
  }
  void setEmpty()   => state.value = ViewState.empty;
  void setSuccess() => state.value = ViewState.success;

  /// Wraps an async operation with standard error handling.
  Future<void> runAsync(Future<void> Function() fn, {bool showError = true}) async {
    try {
      setLoading();
      await fn();
    } catch (e) {
      final ex = e is AppException ? e : ExceptionHandler.handle(e);
      setError(ex.message);
      if (showError) FerosSnackbar.error(ex.message);
    }
  }
}
