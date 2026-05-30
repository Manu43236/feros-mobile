import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  ImageUtils._();

  static final _picker = ImagePicker();

  static Future<File?> pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (xFile == null) return null;
    return _compress(File(xFile.path));
  }

  static Future<File?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (xFile == null) return null;
    return _compress(File(xFile.path));
  }

  static const int _maxBytes = 1 * 1024 * 1024; // 1MB

  static Future<File> _compress(File file) async {
    final dir = await getTemporaryDirectory();
    int quality = 75;
    File output = file;

    while (quality >= 20) {
      final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path, target,
        quality: quality,
        minWidth: 800,
        minHeight: 600,
      );
      if (result == null) break;
      output = File(result.path);
      if (await output.length() <= _maxBytes) break;
      quality -= 15;
    }

    return output;
  }
}
