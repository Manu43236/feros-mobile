import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/popups/feros_dialog.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/upload_service.dart';

class SupervisorProfileController extends GetxController {
  final _auth   = Get.find<AuthService>();
  final _api    = Get.find<ApiClient>();
  final _upload = Get.find<UploadService>();

  AuthService get auth => _auth;

  final appVersion = 'FEROS'.obs;

  // ── profile ──────────────────────────────────────────────────────────────────
  final profile         = Rxn<Map<String, dynamic>>();
  final isLoadingProfile = true.obs;
  final isSavingProfile  = false.obs;
  final isUploadingPhoto = false.obs;

  // ── documents ─────────────────────────────────────────────────────────────────
  final documents        = <Map<String, dynamic>>[].obs;
  final isLoadingDocs    = false.obs;
  final isAddingDoc      = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = 'FEROS v${info.version}';
  }

  int get _userId => _auth.user?.userId ?? 0;

  Future<void> fetchProfile() async {
    isLoadingProfile.value = true;
    try {
      final res = await _api.get(ApiEndpoints.staffProfileById(_userId));
      profile.value = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[Profile] fetch error: $e');
    }
    isLoadingProfile.value = false;
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    isSavingProfile.value = true;
    try {
      await _api.put(ApiEndpoints.staffProfileById(_userId), data: data);
      await fetchProfile();
      FerosSnackbar.success('Profile updated');
      Get.back();
    } catch (e) {
      FerosSnackbar.error('Failed to update profile');
    }
    isSavingProfile.value = false;
  }

  Future<void> uploadProfilePhoto(File file) async {
    isUploadingPhoto.value = true;
    try {
      final url = await _upload.uploadFileGetPublicUrl(
        file,
        folder: 'tenants/images/users/$_userId/profile',
      );
      await _api.put(ApiEndpoints.staffProfileById(_userId), data: {
        ...?profile.value,
        'profilePhotoUrl': url,
      });
      // Update cached user so avatar persists without re-login
      final updatedUser = _auth.user?.copyWith(profilePhotoUrl: url);
      if (updatedUser != null) {
        await _auth.saveSession(updatedUser.token, updatedUser);
      }
      await fetchProfile();
      FerosSnackbar.success('Photo updated');
    } catch (e) {
      FerosSnackbar.error('Failed to upload photo');
    }
    isUploadingPhoto.value = false;
  }

  // ── documents ─────────────────────────────────────────────────────────────────
  Future<void> fetchDocuments() async {
    isLoadingDocs.value = true;
    try {
      final res = await _api.get(ApiEndpoints.staffDocuments(_userId));
      documents.assignAll(
        ((res.data as Map<String, dynamic>)['data'] as List)
            .cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      debugPrint('[Profile] docs fetch error: $e');
    }
    isLoadingDocs.value = false;
  }

  Future<bool> addDocument({
    required int documentTypeId,
    String? documentNumber,
    String? issueDate,
    String? expiryDate,
    String? remarks,
    File? file,
  }) async {
    isAddingDoc.value = true;
    try {
      String? fileUrl;
      if (file != null) {
        fileUrl = await _upload.uploadFileGetPublicUrl(
          file,
          folder: 'tenants/documents/staff/$_userId',
        );
      }
      await _api.post(ApiEndpoints.staffDocuments(_userId), data: {
        'documentTypeId': documentTypeId,
        if (documentNumber != null && documentNumber.isNotEmpty)
          'documentNumber': documentNumber,
        if (issueDate != null && issueDate.isNotEmpty) 'issueDate': issueDate,
        if (expiryDate != null && expiryDate.isNotEmpty) 'expiryDate': expiryDate,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        if (fileUrl != null) 'fileUrl': fileUrl, // ignore: use_null_aware_elements
      });
      await fetchDocuments();
      FerosSnackbar.success('Document added');
      return true;
    } catch (e) {
      FerosSnackbar.error('Failed to add document');
      return false;
    } finally {
      isAddingDoc.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await FerosDialog.confirm(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: true,
    );
    if (confirmed) _auth.logout();
  }
}
