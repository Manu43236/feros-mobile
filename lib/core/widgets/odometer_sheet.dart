import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../popups/feros_snackbar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OdometerResult {
  final double odometer;
  final String? photoUrl;
  OdometerResult({required this.odometer, this.photoUrl});
}

Future<OdometerResult?> showOdometerSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String buttonLabel,
  required Color buttonColor,
  required String instruction,
  double? minOdometer,
}) async {
  File? capturedImage;
  final odometerController = TextEditingController();
  bool isProcessing = false;

  return await showModalBottomSheet<OdometerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(instruction,
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),

            // Photo capture
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (picked == null) return;

                setSheetState(() {
                  capturedImage = File(picked.path);
                  isProcessing = true;
                });

                try {
                  final inputImage = InputImage.fromFile(capturedImage!);
                  final recognizer = TextRecognizer();
                  final result = await recognizer.processImage(inputImage);
                  recognizer.close();

                  final candidates = <int>{};

                  // Strategy 1: direct regex on full text
                  RegExp(r'\d{4,7}').allMatches(result.text).forEach((m) {
                    final v = int.tryParse(m.group(0)!);
                    if (v != null) candidates.add(v);
                  });

                  // Strategy 2: per-line digit extraction.
                  // Joins all elements in a line and strips non-digits.
                  // Handles: split digits ("1"+"25075" → 125075)
                  // and LCD misreads ("Z50"+"75" → 5075).
                  for (final block in result.blocks) {
                    for (final line in block.lines) {
                      final digits = line.elements
                          .map((e) => e.text)
                          .join('')
                          .replaceAll(RegExp(r'[^\d]'), '');
                      if (digits.length >= 4 && digits.length <= 7) {
                        final v = int.tryParse(digits);
                        if (v != null) candidates.add(v);
                      }
                    }
                  }

                  if (candidates.isNotEmpty) {
                    final sorted = candidates.toList()
                      ..sort((a, b) => b.compareTo(a));
                    odometerController.text = sorted.first.toString();
                  }
                } catch (_) {}

                setSheetState(() => isProcessing = false);
              },
              child: Container(
                width: double.infinity,
                height: capturedImage != null ? 160 : 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: capturedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(capturedImage!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover),
                          ),
                          if (isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text('lbl_reading_odm'.tr,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('btn_retake'.tr,
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 28, color: AppColors.mutedText),
                          const SizedBox(height: 6),
                          Text('lbl_tap_odm_photo'.tr,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.mutedText)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: odometerController,
              keyboardType: TextInputType.number,
              autofocus: capturedImage == null,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: hint,
                labelStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
                suffixText: 'km',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
              ),
            ),
            if (minOdometer != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'lbl_odm_min_hint'.trParams({'value': minOdometer.toStringAsFixed(0)}),
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val =
                      double.tryParse(odometerController.text.trim());
                  if (val == null || val <= 0) {
                    FerosSnackbar.error('err_invalid_odm'.tr);
                    return;
                  }
                  if (minOdometer != null && val < minOdometer) {
                    FerosSnackbar.error(
                      'err_odm_below_current'.trParams({'value': minOdometer.toStringAsFixed(0)}),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(OdometerResult(odometer: val));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(buttonLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
