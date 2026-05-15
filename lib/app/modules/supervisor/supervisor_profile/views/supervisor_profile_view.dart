import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../controllers/supervisor_profile_controller.dart';
import 'change_pin_view.dart';

class SupervisorProfileView extends GetView<SupervisorProfileController> {
  const SupervisorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.auth.user;
    return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.navy,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar + Name ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.navy,
                      child: Text(
                        FerosStringUtils.initials(user?.name ?? ''),
                        style: AppTextStyles.heading2
                            .copyWith(color: Colors.white, fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user?.name ?? '—',
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(user?.role ?? ''),
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Details ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user?.phone ?? '—',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: user?.companyName ?? '—',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: '#${user?.userId ?? '—'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Change PIN ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline,
                      color: AppColors.navy, size: 22),
                  title: Text('Change PIN',
                      style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.mutedText),
                  onTap: () => Get.to(() => const ChangePinView()),
                ),
              ),
              const SizedBox(height: 24),

              // ── Logout ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('Logout',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── App version ───────────────────────────────────
              Center(
                child: Text('FEROS v1.0.0',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ),
              const SizedBox(height: 8),
            ],
          ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DRIVER':       return 'Driver';
      case 'CLEANER':      return 'Cleaner';
      case 'SUPERVISOR':   return 'Supervisor';
      case 'OFFICE_STAFF': return 'Office Staff';
      case 'SERVICE_MEN':  return 'Service Men';
      case 'STORE_KEEPER': return 'Store Keeper';
      case 'ADMIN':        return 'Admin';
      default:             return role;
    }
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.mutedText),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            ],
          ),
        ],
      ),
    );
  }
}
