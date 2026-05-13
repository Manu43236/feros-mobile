import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../popups/feros_snackbar.dart';

/// Generic in-app PDF viewer.
/// Renders PDFs natively (Android PDFRenderer / iOS PDFKit).
/// Provides a download/share button in the AppBar.
///
/// Usage:
/// ```dart
/// Get.to(() => PdfViewerView(
///   file: file,
///   title: 'Visakhapatnam → Guntur',
///   subtitle: 'LR-2026-001',    // optional
/// ));
/// ```
class PdfViewerView extends StatefulWidget {
  final File   file;
  final String title;
  final String? subtitle;

  const PdfViewerView({
    super.key,
    required this.file,
    required this.title,
    this.subtitle,
  });

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  int  _totalPages  = 0;
  int  _currentPage = 0;
  bool _pdfReady    = false;

  Future<void> _share() async {
    try {
      final xFile = XFile(widget.file.path, mimeType: 'application/pdf');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: widget.subtitle != null
              ? '${widget.title} — ${widget.subtitle}'
              : widget.title,
        ),
      );
    } catch (e) {
      FerosSnackbar.error('Could not share PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontFamily: 'Inter',
                  fontSize: 11,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Download / Share',
            onPressed: _share,
          ),
        ],
        bottom: _pdfReady && _totalPages > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Page ${_currentPage + 1} of $_totalPages',
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
            filePath: widget.file.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            fitPolicy: FitPolicy.WIDTH,
            onRender: (pages) => setState(() {
              _totalPages = pages ?? 0;
              _pdfReady   = true;
            }),
            onViewCreated: (controller) {},
            onPageChanged: (page, total) =>
                setState(() => _currentPage = page ?? 0),
            onError: (_) => FerosSnackbar.error('Failed to render PDF'),
          ),
          if (!_pdfReady)
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
    );
  }
}
