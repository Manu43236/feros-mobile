import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../../../core/widgets/language_switcher_tile.dart';
import '../controllers/supervisor_profile_controller.dart';
import 'change_pin_view.dart';
import 'supervisor_profile_edit_view.dart';
import 'supervisor_profile_docs_view.dart';
import '../../../tutorials/tutorials_view.dart';

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
        title: Text('lbl_profile'.tr,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar + Name ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              Obx(() {
                final uploading = controller.isUploadingPhoto.value;
                final photoUrl  = controller.profile.value?['profilePhotoUrl'] as String?
                    ?? user?.profilePhotoUrl;
                return GestureDetector(
                  onTap: uploading ? null : () => _pickPhoto(context),
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    // avatar
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy,
                        border: Border.all(color: AppColors.border, width: 2),
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl == null
                          ? Center(child: Text(
                              FerosStringUtils.initials(user?.name ?? ''),
                              style: AppTextStyles.heading2
                                  .copyWith(color: Colors.white, fontSize: 26)))
                          : null,
                    ),
                    // camera badge
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: uploading ? AppColors.border : AppColors.navy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: uploading
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: Colors.white))
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 12),
              Text(user?.name ?? '—',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(user?.role ?? ''),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Details ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(children: [
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
            ]),
          ),
          const SizedBox(height: 12),

          // ── Actions ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.navy, size: 22),
                title: Text('Edit Profile',
                    style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                onTap: () => Get.to(() => const SupervisorProfileEditView(),
                    transition: Transition.cupertino),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: AppColors.navy, size: 22),
                title: Text('My Documents',
                    style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                onTap: () => Get.to(() => const SupervisorProfileDocsView(),
                    transition: Transition.cupertino),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.navy, size: 22),
                title: Text('lbl_change_pin'.tr,
                    style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                onTap: () => Get.to(() => const ChangePinView()),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: AppColors.navy, size: 22),
                title: Text('Training Tutorials',
                    style: AppTextStyles.body.copyWith(color: AppColors.navy)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                onTap: () => Get.to(() => const TutorialsView()),
              ),
              const Divider(height: 1, indent: 56),
              const LanguageSwitcherTile(),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: Text('btn_logout'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Delete Account (dummy for Play Store) ─────────────
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text('lbl_version'.tr,
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.navy),
            title: const Text('Take Photo',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            onTap: () => Get.back(result: ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.navy),
            title: const Text('Choose from Gallery',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            onTap: () => Get.back(result: ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) controller.uploadProfilePhoto(File(picked.path));
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          const Text('Delete Account',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'Your admin will be notified and your account will be permanently deleted within 72 hours.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DRIVER':          return 'role_driver'.tr;
      case 'CLEANER':         return 'role_cleaner'.tr;
      case 'SUPERVISOR':      return 'role_supervisor'.tr;
      case 'OFFICE_STAFF':    return 'role_office_staff'.tr;
      case 'SERVICE_MANAGER': return 'role_service_manager'.tr;
      case 'STORE_KEEPER':    return 'role_store_keeper'.tr;
      case 'ADMIN':           return 'role_admin'.tr;
      default:                return role;
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
      child: Row(children: [
        Icon(icon, size: 22, color: AppColors.mutedText),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
        ]),
      ]),
    );
  }
}
