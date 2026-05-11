import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  PermissionUtils._();

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> requestStorage() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> hasCamera() async =>
      (await Permission.camera.status).isGranted;

  static Future<bool> hasLocation() async =>
      (await Permission.locationWhenInUse.status).isGranted;
}
