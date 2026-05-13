import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../controllers/driver_profile_controller.dart';

class DriverProfileView extends StatelessWidget {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DriverProfileController>(
      init: DriverProfileController(),
      builder: (ctrl) {
        final user = ctrl.auth.user;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.navy,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
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

                    // Trip count stat (Driver / Cleaner only)
                    if (ctrl.showTrips) ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, indent: 40, endIndent: 40),
                      const SizedBox(height: 20),
                      Obx(() => _TripStat(count: ctrl.totalTrips.value)),
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
              const SizedBox(height: 24),

              // ── Logout ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctrl.logout,
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
      },
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
        Text('Trips Completed',
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
