import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import 'pdf_viewer_controller.dart';

/// Generic in-app PDF viewer.
/// Renders PDFs natively (Android PDFRenderer / iOS PDFKit).
///
/// Usage:
/// ```dart
/// Get.to(
///   () => const PdfViewerView(),
///   binding: PdfViewerBinding(),
///   arguments: {'file': file, 'title': 'My Doc', 'subtitle': 'optional'},
/// );
/// ```
class PdfViewerView extends GetView<PdfViewerController> {
  const PdfViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (controller.subtitle != null)
              Text(
                controller.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontFamily: 'Inter',
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Download / Share',
            onPressed: controller.share,
          ),
        ],
        bottom: controller.pdfReady.value && controller.totalPages.value > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Page ${controller.currentPage.value + 1} of ${controller.totalPages.value}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'Inter',
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: controller.file.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            fitPolicy: FitPolicy.WIDTH,
            onRender: (pages) {
              controller.totalPages.value = pages ?? 0;
              controller.pdfReady.value   = true;
            },
            onViewCreated: (_) {},
            onPageChanged: (page, _) =>
                controller.currentPage.value = page ?? 0,
            onError: (_) => Get.snackbar(
              'Error', 'Failed to render PDF',
              backgroundColor: const Color(0xFFDC2626),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            ),
          ),
          if (!controller.pdfReady.value)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Loading PDF…',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    ));
  }
}
