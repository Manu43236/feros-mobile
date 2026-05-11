class FerosValidators {
  FerosValidators._();

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (v.trim().length != 10) return 'Enter a valid 10-digit phone number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Enter a valid Indian phone number';
    return null;
  }

  static String? pin(String? v) {
    if (v == null || v.isEmpty) return 'PIN is required';
    if (v.length != 4) return 'PIN must be 4 digits';
    if (!RegExp(r'^\d{4}$').hasMatch(v)) return 'PIN must contain only digits';
    return null;
  }

  static String? required(String? v, [String? fieldName]) {
    if (v == null || v.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? amount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Amount is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid amount';
    if (n <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Value is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }
}
