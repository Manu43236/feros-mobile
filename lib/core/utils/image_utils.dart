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

  static Future<File> _compress(File file) async {
    final dir = await getTemporaryDirectory();
    final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path, target,
      quality: 75,
      minWidth: 800,
      minHeight: 600,
    );
    return result != null ? File(result.path) : file;
  }
}
