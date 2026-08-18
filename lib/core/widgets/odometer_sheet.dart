import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../popups/feros_snackbar.dart';
import '../theme/app_text_styles.dart';

class OdometerResult {
  final double odometer;
  final String? photoUrl;
  OdometerResult({required this.odometer, this.photoUrl});
}

// ── App-theme light palette ───────────────────────────────────────────────────
const _kBg       = Colors.white;
const _kSurface  = Color(0xFFF8FAFC);
const _kBorderDm = Color(0xFFE2E8F0);
const _kBorderLt = Color(0xFFCBD5E1);
const _kNavy     = Color(0xFF1E3A5F);
const _kMuted    = Color(0xFF64748B);
const _kGreen    = Color(0xFF16A34A);
const _kAmber    = Color(0xFFD97706);
const _kRed      = Color(0xFFDC2626);
const _kOrange   = Color(0xFFF97316); // FEROS needle colour
const _kRadium   = Color(0xFFBDFF00); // luminescent radium yellow-green
const _kRadiumDim= Color(0xFF6B8F00); // dimmer radium for minor ticks
const _kFace     = Color(0xFF0A1628); // dark gauge face
const _kBezel    = Color(0xFF1E3A5F); // outer bezel ring

// Scale: 0 – 300 000 km (absolute)
const _kMaxKm = 300000.0;

// ── Analog odometer painter ───────────────────────────────────────────────────
class _SpeedometerPainter extends CustomPainter {
  final double value;       // 0.0 – 1.0  (fullKm / _kMaxKm)
  final double? lastValue;  // 0.0 – 1.0  last reading marker, nullable
  final bool hasValue;

  const _SpeedometerPainter({
    required this.value,
    required this.hasValue,
    this.lastValue,
  });

  static const _majorCount   = 6;  // 6 intervals → labels 0,50,100,150,200,250,300
  static const _minorPerMajor= 4;  // 4 minor ticks between each major
  static const _totalTicks   = _majorCount * _minorPerMajor; // 24

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height * 0.93;
    final radius = size.width * 0.43;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // ── 1. Dark gauge face (filled semicircle) ───────────────────────────────
    final facePath = Path()
      ..moveTo(cx - radius - 12, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius + 12),
        startAngle, sweepAngle, false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(facePath, Paint()..color = _kFace);

    // ── 2. Outer bezel ring ──────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius + 10),
      startAngle - 0.04, sweepAngle + 0.08, false,
      Paint()
        ..color = _kBezel
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // ── 3. Inner dark track groove ───────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius - 6),
      startAngle, sweepAngle, false,
      Paint()
        ..color = const Color(0xFF1A2A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    // ── 4. Progress arc (orange) ─────────────────────────────────────────────
    if (hasValue && value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - 6),
        startAngle, sweepAngle * value.clamp(0.0, 1.0), false,
        Paint()
          ..color = _kOrange.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── 5. Tick marks + radium labels ────────────────────────────────────────
    for (int i = 0; i <= _totalTicks; i++) {
      final isMajor = i % _minorPerMajor == 0;
      final angle   = startAngle + (sweepAngle / _totalTicks) * i;
      final dx      = math.cos(angle);
      final dy      = math.sin(angle);

      final outerR = radius - 14 + (isMajor ? 0 : 4);
      final innerR = isMajor ? radius - 32 : radius - 24;

      // glow blur on major ticks
      if (isMajor) {
        canvas.drawLine(
          Offset(cx + dx * innerR, cy + dy * innerR),
          Offset(cx + dx * outerR, cy + dy * outerR),
          Paint()
            ..color = _kRadium.withOpacity(0.45)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // solid tick
      canvas.drawLine(
        Offset(cx + dx * innerR, cy + dy * innerR),
        Offset(cx + dx * outerR, cy + dy * outerR),
        Paint()
          ..color = isMajor ? _kRadium : _kRadiumDim.withOpacity(0.5)
          ..strokeWidth = isMajor ? 2.0 : 1.0
          ..strokeCap = StrokeCap.round,
      );

      // label at major ticks (drawn inside, between tick and hub)
      if (isMajor) {
        final majorIndex = i ~/ _minorPerMajor;
        final labelKm    = majorIndex * 50; // 0,50,100,...,300
        final label      = '$labelKm';
        final labelR     = radius - 46;
        final tx         = cx + math.cos(angle) * labelR;
        final ty         = cy + math.sin(angle) * labelR;

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: _kRadium,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              shadows: [Shadow(color: _kRadium.withOpacity(0.9), blurRadius: 5)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(tx - tp.width / 2, ty - tp.height / 2);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // ── 6. Last-reading marker (amber) ───────────────────────────────────────
    if (lastValue != null) {
      final lrAngle = startAngle + sweepAngle * lastValue!.clamp(0.0, 1.0);
      final dx = math.cos(lrAngle);
      final dy = math.sin(lrAngle);
      canvas.drawLine(
        Offset(cx + dx * (radius - 32), cy + dy * (radius - 32)),
        Offset(cx + dx * (radius - 14), cy + dy * (radius - 14)),
        Paint()
          ..color = _kAmber
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }


  }

  @override
  bool shouldRepaint(_SpeedometerPainter o) =>
      o.value != value || o.hasValue != hasValue || o.lastValue != lastValue;
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


  // First 2 digits of current odometer — shown locked in grey
  final prefix = minOdometer != null
      ? minOdometer.toStringAsFixed(0).padLeft(6, '0').substring(0, 2)
      : '00';

  // Driver types only last 4 digits — always starts empty
  final ctrl = TextEditingController();
  final focusNode = FocusNode();
  // Decimal part — 2 digits, defaults to 00
  final ctrlDecimal = TextEditingController();
  final focusDecimal = FocusNode();

  // Reconstruct full 6-digit value with auto-rollover + decimal
  double reconstructFull(String typed, {String dec = ''}) {
    if (typed.isEmpty) return 0;
    final padded = typed.padLeft(4, '0');
    final combined = int.tryParse(prefix + padded) ?? 0;
    final decVal = (int.tryParse(dec.padRight(2, '0').substring(0, 2)) ?? 0) / 100.0;
    if (minOdometer != null && combined < minOdometer) {
      final prefixInt = int.parse(prefix);
      if (prefixInt == 99) return double.parse('00$padded') + decVal;
      final newPrefix = (prefixInt + 1).toString().padLeft(2, '0');
      return double.parse(newPrefix + padded) + decVal;
    }
    return combined.toDouble() + decVal;
  }

  // Live prefix display — updates as driver types each digit
  // Uses min/max possible range to determine rollover certainty
  String livePrefix(String typed) {
    if (typed.isEmpty || minOdometer == null) return prefix;
    final remaining = 4 - typed.length;
    final maxPossible = int.tryParse(
          prefix + typed + '9' * remaining,
        ) ??
        0;
    if (maxPossible < minOdometer) {
      // rollover is certain
      final prefixInt = int.parse(prefix);
      if (prefixInt == 99) return '00';
      return (prefixInt + 1).toString().padLeft(2, '0');
    }
    return prefix;
  }

  // 100 kmph × 24 h — physically impossible ceiling per day
  double? maxOdometer() {
    if (tripStartDate == null || minOdometer == null) return null;
    final days = DateTime.now().difference(tripStartDate).inDays + 1;
    return minOdometer + (days * 2400);
  }

  // Absolute position on the 0–300 000 km scale
  double needleValue(double fullVal, double? _) =>
      (fullVal / _kMaxKm).clamp(0.0, 1.0);

  double? lastReadingNormalized(double? min) =>
      min == null ? null : (min / _kMaxKm).clamp(0.0, 1.0);

  final result = await showModalBottomSheet<OdometerResult>(
        useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void confirm() {
          final typed = ctrl.text.trim();
          if (typed.isEmpty) {
            FerosSnackbar.error('err_invalid_odm'.tr);
            return;
          }
          final val = reconstructFull(typed, dec: ctrlDecimal.text.trim());
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


        final typed       = ctrl.text.trim();
        final typedDec    = ctrlDecimal.text.trim();
        final hasValue    = typed.isNotEmpty;
        final fullVal     = hasValue ? reconstructFull(typed, dec: typedDec) : 0.0;
        final needlePos   = needleValue(fullVal, minOdometer);
        final lastNorm    = lastReadingNormalized(minOdometer);
        // display decimal — what's typed or '00'
        final dispDec     = typedDec.padRight(2, '0').substring(0, 2);
        final shownPrefix = livePrefix(typed);
        final canConfirm  = typed.length == 4;
        final ceiling     = maxOdometer();
        final aboveMax    = ceiling != null && canConfirm && fullVal > ceiling;

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
                      height: 190,
                      child: CustomPaint(
                        painter: _SpeedometerPainter(
                          value: needlePos,
                          hasValue: hasValue,
                          lastValue: lastNorm,
                        ),
                        child: Align(
                          alignment: const Alignment(0, 0.92),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Odometer drum display ──────────────────────
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF050E1A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF2D4A6F),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x55F97316),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // prefix digits — highlight when all 4 typed
                                    ...shownPrefix.split('').map((ch) =>
                                      _OdometerDigit(ch: ch, active: typed.length == 4),
                                    ),
                                    // typed digits — bright amber / dash
                                    ...List.generate(4, (i) {
                                      final ch = i < typed.length
                                          ? typed[i]
                                          : '–';
                                      return _OdometerDigit(
                                        ch: ch,
                                        active: i < typed.length,
                                      );
                                    }),
                                    // decimal dot
                                    const _OdometerDigit(ch: '.', active: true),
                                    // 2 decimal digits
                                    _OdometerDigit(ch: dispDec[0], active: typedDec.length >= 1),
                                    _OdometerDigit(ch: dispDec[1], active: typedDec.length >= 2),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'KM',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // input row — decimal appears only after 4 digits entered
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // main 4-digit field
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              focusNode: focusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              autofocus: true,
                              onChanged: (v) {
                                setState(() {});
                                if (v.length == 4) focusDecimal.requestFocus();
                              },
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _kNavy,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                hintText: '----',
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
                              ),
                            ),
                          ),

                          // decimal separator + field — only when 4 digits entered
                          if (typed.length == 4) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '.',
                              style: TextStyle(
                                color: _kMuted,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: ctrlDecimal,
                                focusNode: focusDecimal,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (_) => setState(() {}),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _kNavy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText: '00',
                                  hintStyle: const TextStyle(
                                    color: _kMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: _kSurface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

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

                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canConfirm && !aboveMax ? confirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canConfirm && !aboveMax
                                ? buttonColor
                                : const Color(0xFFCBD5E1),
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
            ),
          ),
        );
      },
    ),
  );

  focusNode.dispose();
  ctrl.dispose();
  focusDecimal.dispose();
  ctrlDecimal.dispose();
  return result;
}

// ── Single odometer drum digit ────────────────────────────────────────────────
class _OdometerDigit extends StatelessWidget {
  final String ch;
  final bool active;
  const _OdometerDigit({required this.ch, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 24,
      alignment: Alignment.center,
      child: Text(
        ch,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          letterSpacing: 0,
          color: active
              ? const Color(0xFFFFB347) // warm amber when typed
              : const Color(0xFF3A5070), // dim for prefix / placeholder
          shadows: active
              ? const [
                  Shadow(
                    color: Color(0xAAFF8C00),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
