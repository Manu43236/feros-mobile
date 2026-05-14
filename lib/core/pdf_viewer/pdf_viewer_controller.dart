import 'dart:io';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../popups/feros_snackbar.dart';

class PdfViewerController extends GetxController {
  late final File   file;
  late final String title;
  late final String? subtitle;

  final totalPages  = 0.obs;
  final currentPage = 0.obs;
  final pdfReady    = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    file     = args['file']     as File;
    title    = args['title']    as String;
    subtitle = args['subtitle'] as String?;
  }

  Future<void> share() async {
    try {
      final xFile = XFile(file.path, mimeType: 'application/pdf');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: subtitle != null ? '$title — $subtitle' : title,
        ),
      );
    } catch (_) {
      FerosSnackbar.error('Could not share PDF');
    }
  }
}
