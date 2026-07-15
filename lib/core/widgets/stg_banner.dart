import 'package:flutter/material.dart';
import '../utils/env_config.dart';

class StgBanner extends StatelessWidget {
  final Widget child;

  const StgBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!EnvConfig.isStg) return child;

    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        child,
        Positioned(
          top: topPadding,
          right: 0,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(72, 72),
              painter: _StgRibbonPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StgRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE53935);
    final path = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..close();
    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(size.width * 0.72, size.height * 0.18);
    canvas.rotate(0.785398); // 45 degrees
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'STG',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
