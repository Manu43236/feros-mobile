import 'package:intl/intl.dart';

class FerosDateUtils {
  FerosDateUtils._();

  static String formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) { return iso; }
  }

  static String formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, h:mm a').format(dt);
    } catch (_) { return iso; }
  }

  static String formatDateInput(DateTime dt) =>
      DateFormat('yyyy-MM-dd').format(dt);

  static String formatMonthYear(DateTime dt) =>
      DateFormat('MMMM yyyy').format(dt);

  static String formatShortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM').format(dt);
    } catch (_) { return iso; }
  }

  static String timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return formatDate(iso);
    } catch (_) { return ''; }
  }

  static bool isExpired(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    try { return DateTime.parse(iso).isBefore(DateTime.now()); }
    catch (_) { return false; }
  }

  static int daysUntil(String? iso) {
    if (iso == null || iso.isEmpty) return 999;
    try {
      final dt = DateTime.parse(iso);
      return dt.difference(DateTime.now()).inDays;
    } catch (_) { return 999; }
  }

  static String today() => formatDateInput(DateTime.now());
  static String firstDayOfMonth() {
    final now = DateTime.now();
    return formatDateInput(DateTime(now.year, now.month, 1));
  }
}
