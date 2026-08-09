import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../popups/feros_snackbar.dart';
import '../theme/app_text_styles.dart';

class OdometerResult {
  final double odometer;
  final String? photoUrl;
  OdometerResult({required this.odometer, this.photoUrl});
}

// ── App-theme light palette ───────────────────────────────────────────────────
const _kBg      = Colors.white;
const _kSurface = Color(0xFFF8FAFC);
const _kBorderDm = Color(0xFFE2E8F0);
const _kBorderLt = Color(0xFFCBD5E1);
const _kNavy    = Color(0xFF1E3A5F);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF16A34A);
const _kAmber   = Color(0xFFD97706);
const _kRed     = Color(0xFFDC2626);

// ── Speedometer arc painter ───────────────────────────────────────────────────
class _SpeedometerPainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final bool hasValue;
  const _SpeedometerPainter({required this.value, required this.hasValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.90;
    final radius = size.width * 0.42;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    const tickCount = 8;

    // track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // progress arc
    if (hasValue) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = _kGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // tick marks
    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (sweepAngle / tickCount) * i;
      final isMajor = i % 2 == 0;
      final inner = isMajor ? radius - 14.0 : radius - 9.0;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      canvas.drawLine(
        Offset(cx + dx * inner, cy + dy * inner),
        Offset(cx + dx * (radius + 2), cy + dy * (radius + 2)),
        Paint()
          ..color = isMajor ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)
          ..strokeWidth = isMajor ? 2.0 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // needle
    final needleAngle = startAngle + sweepAngle * value.clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(cx, cy),
      Offset(
        cx + math.cos(needleAngle) * (radius - 6),
        cy + math.sin(needleAngle) * (radius - 6),
      ),
      Paint()
        ..color = hasValue ? _kGreen : const Color(0xFFCBD5E1)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // hub
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()..color = hasValue ? _kGreen : const Color(0xFFCBD5E1),
    );
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SpeedometerPainter o) =>
      o.value != value || o.hasValue != hasValue;
}

// ── Sheet ─────────────────────────────────────────────────────────────────────
Future<OdometerResult?> showOdometerSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String buttonLabel,
  required Color buttonColor,
  required String instruction,
  double? minOdometer,
  DateTime? tripStartDate, // when provided, enforces physics-based max delta
}) async {
  File? capturedImage;
  bool isProcessing = false;
  final ctrl = TextEditingController(
    text: minOdometer != null ? minOdometer.toStringAsFixed(0) : '',
  );
  final focusNode = FocusNode();

  // 100 kmph × 24 h — physically impossible ceiling per day
  double? maxOdometer() {
    if (tripStartDate == null || minOdometer == null) return null;
    final days = DateTime.now().difference(tripStartDate).inDays + 1;
    return minOdometer + (days * 2400);
  }

  double needleValue(String text, double? min) {
    final v = double.tryParse(text);
    if (v == null || v <= 0) return 0.0;
    final base = (min ?? 0).clamp(0, 900000).toDouble();
    final ceiling = math.max(base + 100000, 999999).toDouble();
    return ((v - base) / (ceiling - base)).clamp(0.0, 1.0);
  }

  final result = await showModalBottomSheet<OdometerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void confirm() {
          final val = double.tryParse(ctrl.text.trim());
          if (val == null || val <= 0) {
            FerosSnackbar.error('err_invalid_odm'.tr);
            return;
          }
          if (minOdometer != null && val < minOdometer) {
            FerosSnackbar.error(
              'err_odm_below_current'.trParams({
                'value': minOdometer.toStringAsFixed(0),
              }),
            );
            return;
          }
          final ceiling = maxOdometer();
          if (ceiling != null && val > ceiling) {
            final days = DateTime.now().difference(tripStartDate!).inDays + 1;
            FerosSnackbar.error(
              'Reading too high. Max possible for $days day(s) is '
              '${ceiling.toStringAsFixed(0)} km. Please verify.',
            );
            return;
          }
          Navigator.of(ctx).pop(OdometerResult(odometer: val));
        }

        Future<void> scanPhoto() async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          if (picked == null) return;
          setState(() {
            capturedImage = File(picked.path);
            isProcessing = true;
          });
          try {
            final recognizer = TextRecognizer();
            final res = await recognizer.processImage(
              InputImage.fromFile(capturedImage!),
            );
            recognizer.close();
            final candidates = <int>{};
            RegExp(r'\d{4,7}').allMatches(res.text).forEach((m) {
              final v = int.tryParse(m.group(0)!);
              if (v != null) candidates.add(v);
            });
            for (final block in res.blocks) {
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
              ctrl.text = sorted.first.toString();
            }
          } catch (_) {}
          setState(() => isProcessing = false);
        }

        final hasValue =
            ctrl.text.trim().isNotEmpty &&
            double.tryParse(ctrl.text.trim()) != null;
        final needlePos = needleValue(ctrl.text.trim(), minOdometer);
        final enteredVal = double.tryParse(ctrl.text) ?? 0;
        final belowMin =
            minOdometer != null &&
            ctrl.text.isNotEmpty &&
            enteredVal < minOdometer;
        final ceiling = maxOdometer();
        final aboveMax = ceiling != null &&
            ctrl.text.isNotEmpty &&
            enteredVal > ceiling;

        // Constrain sheet height and scroll when keyboard pushes content
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 24 + MediaQuery.of(ctx).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // drag handle
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _kBorderDm,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // title + last reading
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _kNavy,
                              ),
                            ),
                          ),
                          if (minOdometer != null)
                            Text(
                              'Last: ${minOdometer.toStringAsFixed(0)} km',
                              style: AppTextStyles.caption.copyWith(
                                color: _kAmber,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        instruction,
                        style: AppTextStyles.caption.copyWith(color: _kMuted),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // speedometer gauge
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _SpeedometerPainter(
                          value: needlePos,
                          hasValue: hasValue,
                        ),
                        child: Align(
                          alignment: const Alignment(0, 0.45),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasValue ? ctrl.text.trim() : '——',
                                style: TextStyle(
                                  color: hasValue ? _kNavy : _kMuted,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'km',
                                style: TextStyle(
                                  color: _kMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // text field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kNavy,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: const TextStyle(
                            color: _kMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                          filled: true,
                          fillColor: _kSurface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _kBorderDm,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _kBorderDm,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _kGreen,
                              width: 1.5,
                            ),
                          ),
                          suffixText: 'km',
                          suffixStyle: const TextStyle(
                            color: _kMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // below-min warning
                    if (belowMin) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: _kRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'lbl_odm_min_hint'.trParams({
                                  'value': minOdometer.toStringAsFixed(0),
                                }),
                                style: AppTextStyles.caption.copyWith(
                                  color: _kRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (aboveMax) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 13, color: _kRed),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Reading exceeds max possible for this trip '
                                '(${ceiling.toStringAsFixed(0)} km). '
                                'Please recheck.',
                                style: AppTextStyles.caption
                                    .copyWith(color: _kRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Scan + confirm row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Scan button
                          GestureDetector(
                            onTap: scanPhoto,
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _kSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _kBorderDm,
                                  width: 1.5,
                                ),
                              ),
                              child: capturedImage != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.file(
                                            capturedImage!,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        isProcessing
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: _kNavy,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.refresh,
                                                size: 16,
                                                color: _kMuted,
                                              ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 20,
                                          color: _kMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Scan',
                                          style: AppTextStyles.caption.copyWith(
                                            color: _kMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Confirm button
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: confirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  buttonLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  focusNode.dispose();
  ctrl.dispose();
  return result;
}
