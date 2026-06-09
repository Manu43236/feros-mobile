class FerosStringUtils {
  FerosStringUtils._();

  static String capitalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String truncate(String? s, int max) {
    if (s == null) return '';
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  static String orDash(String? s) => (s == null || s.isEmpty) ? '—' : s;

  static String roleLabel(String? role) {
    switch (role) {
      case 'ADMIN':        return 'Admin';
      case 'OFFICE_STAFF': return 'Office Staff';
      case 'SUPERVISOR':   return 'Supervisor';
      case 'DRIVER':       return 'Driver';
      case 'CLEANER':      return 'Cleaner';
      case 'SERVICE_MANAGER': return 'Service Manager';
      case 'TECHNICIAN':      return 'Technician';
      case 'STORE_KEEPER': return 'Store Keeper';
      case 'SUPER_ADMIN':  return 'Super Admin';
      default:             return role ?? '';
    }
  }
}
