class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException() : super('No internet connection. Please check your network.');
}

class TimeoutException extends AppException {
  TimeoutException() : super('Request timed out. Please try again.');
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Session expired. Please login again.');
}

class ForbiddenException extends AppException {
  ForbiddenException([String? msg])
      : super(msg ?? "You don't have permission for this action.");
}

class NotFoundException extends AppException {
  NotFoundException([String? msg]) : super(msg ?? 'Record not found.');
}

class PaymentRequiredException extends AppException {
  PaymentRequiredException()
      : super('Your subscription has expired. Please upgrade to continue.');
}

class ServerException extends AppException {
  ServerException([String? msg])
      : super(msg ?? 'Server error. Please try again later.');
}

class ValidationException extends AppException {
  ValidationException(String msg) : super(msg);
}

class UnknownException extends AppException {
  UnknownException() : super('Something went wrong. Please try again.');
}

class AccountLockedException extends AppException {
  final DateTime lockedUntil;
  AccountLockedException(this.lockedUntil) : super('ACCOUNT_LOCKED');
}

class WrongPinException extends AppException {
  final int failedAttempts;
  WrongPinException(this.failedAttempts) : super('Invalid mobile number or PIN');
}
