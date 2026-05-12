import 'dart:io';
import 'package:flutter/material.dart';
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

                  final numbers = RegExp(r'\d{4,7}')
                      .allMatches(result.text)
                      .map((m) => int.parse(m.group(0)!))
                      .toList();
                  if (numbers.isNotEmpty) {
                    numbers.sort((a, b) => b.compareTo(a));
                    odometerController.text = numbers.first.toString();
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
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text('Reading ODM…',
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
                              child: Text('Retake',
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
                          Text('Tap to take ODM photo',
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
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val =
                      double.tryParse(odometerController.text.trim());
                  if (val == null || val <= 0) {
                    FerosSnackbar.error('Enter a valid odometer reading');
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
