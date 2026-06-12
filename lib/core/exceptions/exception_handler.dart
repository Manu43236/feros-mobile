import 'package:dio/dio.dart';
import 'app_exception.dart';

class ExceptionHandler {
  ExceptionHandler._();

  static AppException handle(dynamic error) {
    if (error is AppException) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException();

        case DioExceptionType.connectionError:
          return NetworkException();

        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          final msg = _extractMessage(error.response?.data);

          if (status == 400) return ValidationException(msg ?? 'Invalid request.');
          if (status == 401) {
            final body = error.response?.data;
            if (body is Map<String, dynamic>) {
              final data = body['data'];
              if (data is Map<String, dynamic> && data.containsKey('failedAttempts')) {
                return WrongPinException(data['failedAttempts'] as int);
              }
            }
            return UnauthorizedException();
          }
          if (status == 402) return PaymentRequiredException();
          if (status == 403) return ForbiddenException(msg);
          if (status == 404) return NotFoundException(msg);
          if (status == 423) {
            final body = error.response?.data;
            String? lockedUntilStr;
            if (body is Map<String, dynamic>) {
              final data = body['data'];
              if (data is Map<String, dynamic>) {
                lockedUntilStr = data['lockedUntil'] as String?;
              }
            }
            final lockedUntil = lockedUntilStr != null
                ? DateTime.parse(lockedUntilStr)
                : DateTime.now().add(const Duration(minutes: 5));
            return AccountLockedException(lockedUntil);
          }
          if (status != null && status >= 500) return ServerException(msg);
          return ValidationException(msg ?? 'Request failed.');

        default:
          return UnknownException();
      }
    }

    return UnknownException();
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}
