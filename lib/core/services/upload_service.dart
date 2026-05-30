import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class UploadService extends GetxService {
  final _api = Get.find<ApiClient>();

  /// Uploads a file to S3 via backend proxy.
  /// Returns the S3 key string.
  Future<String> uploadFile(File file, {String? folder}) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (folder != null) 'folder': folder,
    });
    final response = await _api.postFormData(ApiEndpoints.upload, formData);
    final data = response.data as Map<String, dynamic>;
    return data['data']['key'] as String;
  }

  /// Uploads a file and returns the public URL (for storing as image URLs).
  Future<String> uploadFileGetPublicUrl(File file, {String? folder}) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (folder != null) 'folder': folder,
    });
    final response = await _api.postFormData(ApiEndpoints.upload, formData);
    final data = response.data as Map<String, dynamic>;
    return data['data']['publicUrl'] as String;
  }
}
