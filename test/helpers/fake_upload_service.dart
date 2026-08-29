import 'dart:io';
import 'package:feros/core/services/upload_service.dart';

class FakeUploadService extends UploadService {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<String> uploadFile(File file, {String? folder}) async =>
      'https://example.com/fake.jpg';

  @override
  Future<String> uploadFileGetPublicUrl(File file, {String? folder}) async =>
      'https://example.com/fake.jpg';
}
