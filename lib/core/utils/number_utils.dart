import 'package:intl/intl.dart';

class FerosNumberUtils {
  FerosNumberUtils._();

  static final _inr = NumberFormat('#,##,##0.00', 'en_IN');
  static final _int = NumberFormat('#,##,##0', 'en_IN');

  static String formatCurrency(num? n) {
    if (n == null) return '₹0.00';
    return '₹${_inr.format(n)}';
  }

  static String formatCurrencyCompact(num? n) {
    if (n == null) return '₹0';
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000)   return '₹${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000)     return '₹${(n / 1000).toStringAsFixed(1)} K';
    return '₹${_inr.format(n)}';
  }

  static String formatNumber(num? n) {
    if (n == null) return '0';
    return _int.format(n);
  }

  static String formatWeight(num? n) {
    if (n == null) return '0 T';
    return '${n.toStringAsFixed(2)} T';
  }

  static String formatKm(num? n) {
    if (n == null) return '0 km';
    return '${_int.format(n)} km';
  }

  static String formatLitres(num? n) {
    if (n == null) return '0 L';
    return '${n.toStringAsFixed(1)} L';
  }

  static String formatPercent(num? n) {
    if (n == null) return '0%';
    return '${n.toStringAsFixed(1)}%';
  }
}
