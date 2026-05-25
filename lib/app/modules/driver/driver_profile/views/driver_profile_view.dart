import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/widgets/language_switcher_tile.dart';
import '../controllers/driver_profile_controller.dart';
import '../../../supervisor/supervisor_profile/views/change_pin_view.dart';

class DriverProfileView extends GetView<DriverProfileController> {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.auth.user;
    return ListView(
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

                    // Trip count stat (Driver / Cleaner only)
                    if (controller.showTrips) ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, indent: 40, endIndent: 40),
                      const SizedBox(height: 20),
                      Obx(() => _TripStat(count: controller.totalTrips.value)),
                    ],
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
                      label: 'lbl_phone'.tr,
                      value: user?.phone ?? '—',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.business_outlined,
                      label: 'lbl_company'.tr,
                      value: user?.companyName ?? '—',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'lbl_user_id'.tr,
                      value: '#${user?.userId ?? '—'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Change PIN + Language ─────────────────────────
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
                    ListTile(
                      leading: const Icon(Icons.lock_outline,
                          color: AppColors.navy, size: 22),
                      title: Text('lbl_change_pin'.tr,
                          style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.mutedText),
                      onTap: () => Get.to(() => const ChangePinView()),
                    ),
                    const Divider(height: 1, indent: 56),
                    const LanguageSwitcherTile(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Logout ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('btn_logout'.tr,
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
                child: Text('lbl_version'.tr,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ),
              const SizedBox(height: 8),
            ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DRIVER':       return 'role_driver'.tr;
      case 'CLEANER':      return 'role_cleaner'.tr;
      case 'SUPERVISOR':   return 'role_supervisor'.tr;
      case 'OFFICE_STAFF': return 'role_office_staff'.tr;
      case 'SERVICE_MEN':  return 'role_service_men'.tr;
      case 'STORE_KEEPER': return 'role_store_keeper'.tr;
      case 'ADMIN':        return 'role_admin'.tr;
      default:             return role;
    }
  }
}

// ── Trip Stat ─────────────────────────────────────────────────────────────────
class _TripStat extends StatelessWidget {
  final int? count;
  const _TripStat({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        count == null
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.navy),
              )
            : Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
        const SizedBox(height: 4),
        Text('lbl_trips_completed'.tr,
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
      ],
    );
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
