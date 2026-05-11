import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class UploadService extends GetxService {
  final _api = Get.find<ApiClient>();

  /// Uploads a file to S3 via backend proxy.
  /// Returns the S3 URL string.
  Future<String> uploadFile(File file, {String? folder}) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      if (folder != null) 'folder': folder,
    });

    final response = await _api.postFormData(ApiEndpoints.upload, formData);
    final data = response.data as Map<String, dynamic>;
    return data['data']['url'] as String;
  }
}
