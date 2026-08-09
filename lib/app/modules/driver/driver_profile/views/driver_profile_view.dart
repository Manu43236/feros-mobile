import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/widgets/doc_file_preview.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/services/audio_guidance_service.dart';
import '../../../../../core/widgets/language_switcher_tile.dart';
import '../controllers/driver_profile_controller.dart';
import '../../../supervisor/supervisor_profile/views/change_pin_view.dart';
import '../../../tutorials/tutorials_view.dart';

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

              // ── My Documents ──────────────────────────────────
              Obx(() {
                if (controller.isDocsLoading.value) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy)),
                  );
                }
                final docs = controller.myDocs;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.badge_outlined, size: 18, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Text('My Documents',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
                      ]),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      if (docs.isEmpty)
                        Text('No documents uploaded yet.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.mutedText))
                      else
                        ...docs.map((d) => _ProfileDocRow(doc: d)),
                    ],
                  ),
                );
              }),
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
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline,
                          color: AppColors.navy, size: 22),
                      title: Text('Training Tutorials',
                          style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.mutedText),
                      onTap: () => Get.to(() => const TutorialsView()),
                    ),
                    const Divider(height: 1, indent: 56),
                    const LanguageSwitcherTile(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Audio Guidance ────────────────────────────────
              _AudioGuidanceCard(),
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
              const SizedBox(height: 12),

              // ── Delete Account ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Account',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── App version ───────────────────────────────────
              Center(
                child: Obx(() => Text(controller.appVersion.value,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText))),
              ),
              const SizedBox(height: 8),
            ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            const Text('Delete Account',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'Your admin will be notified and your account will be permanently deleted within 72 hours.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm',
                style: TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DRIVER':       return 'role_driver'.tr;
      case 'CLEANER':      return 'role_cleaner'.tr;
      case 'SUPERVISOR':   return 'role_supervisor'.tr;
      case 'OFFICE_STAFF': return 'role_office_staff'.tr;
      case 'SERVICE_MANAGER':  return 'role_service_manager'.tr;
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

// ── Profile Doc Row ───────────────────────────────────────────────────────────
class _ProfileDocRow extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _ProfileDocRow({required this.doc});

  Color _expiryColor(String? expiry) {
    if (expiry == null) return AppColors.mutedText;
    try {
      final d    = DateTime.parse(expiry);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0)  return const Color(0xFFDC2626);
      if (days < 60) return const Color(0xFFD97706);
      return const Color(0xFF16A34A);
    } catch (_) {
      return AppColors.mutedText;
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null) return 'No Expiry';
    try {
      final d = DateTime.parse(raw);
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeName  = doc['documentTypeName'] as String? ?? '—';
    final docNumber = doc['documentNumber']   as String?;
    final expiry    = doc['expiryDate']        as String?;
    final fileUrl   = doc['fileUrl']           as String?;
    final verified  = doc['isVerified']        as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(typeName,
                      style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                  if (verified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                  ],
                ]),
                if (docNumber != null)
                  Text(docNumber,
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                Text(_fmtDate(expiry),
                    style: AppTextStyles.caption.copyWith(color: _expiryColor(expiry))),
              ],
            ),
          ),
          if (fileUrl != null && fileUrl.isNotEmpty)
            DocFilePreview(fileUrl: fileUrl, docName: typeName),
        ],
      ),
    );
  }
}

// ── Audio Guidance Card ───────────────────────────────────────────────────────
class _AudioGuidanceCard extends StatelessWidget {
  static const _languages = [
    {'code': 'te', 'label': 'Telugu'},
    {'code': 'en', 'label': 'English'},
  ];

  @override
  Widget build(BuildContext context) {
    final audio = Get.find<AudioGuidanceService>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded,
                  size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Audio Guidance',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy)),
              ),
              Obx(() => Switch(
                    value: audio.isEnabled.value,
                    activeColor: AppColors.navy,
                    onChanged: audio.setEnabled,
                  )),
            ],
          ),
          Obx(() {
            if (!audio.isEnabled.value) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),
                Text('Language',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: audio.language.value,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.navy)),
                  ),
                  items: _languages
                      .map((l) => DropdownMenuItem(
                            value: l['code'],
                            child: Text(l['label']!,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.navy)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) audio.setLanguage(v);
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
