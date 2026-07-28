import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf_viewer/pdf_viewer_view.dart';
import '../pdf_viewer/pdf_viewer_binding.dart';
import '../theme/app_colors.dart';
import 'feros_image_viewer.dart';

bool isImageUrl(String url) {
  final path = url.toLowerCase().split('?').first;
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.gif');
}

class DocFilePreview extends StatefulWidget {
  final String fileUrl;
  final String docName;

  const DocFilePreview({super.key, required this.fileUrl, required this.docName});

  @override
  State<DocFilePreview> createState() => _DocFilePreviewState();
}

class _DocFilePreviewState extends State<DocFilePreview> {
  bool _loading = false;

  Future<void> _openPdf() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final dio      = Dio();
      final dir      = await getTemporaryDirectory();
      final fileName = widget.fileUrl.split('/').last.split('?').first;
      final file     = File('${dir.path}/$fileName');
      final res      = await dio.get<List<int>>(
        widget.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(res.data!);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {'file': file, 'title': widget.docName},
        transition: Transition.cupertino,
      );
    } catch (_) {
      Get.snackbar('Error', 'Could not open document',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isImage = isImageUrl(widget.fileUrl);

    return GestureDetector(
      onTap: isImage
          ? () => FerosImageViewer.show(context, widget.fileUrl)
          : _openPdf,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isImage
            ? CachedNetworkImage(
                imageUrl: widget.fileUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => _iconBox(Icons.image_outlined, isLoading: true),
                errorWidget:  (_, __, ___) => _iconBox(Icons.broken_image_outlined),
              )
            : _iconBox(Icons.picture_as_pdf_outlined, isLoading: _loading),
      ),
    );
  }

  Widget _iconBox(IconData icon, {bool isLoading = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
              ),
            )
          : Icon(icon, size: 26, color: AppColors.navy),
    );
  }
}
