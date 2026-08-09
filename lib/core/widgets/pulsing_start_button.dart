import 'package:flutter/material.dart';

/// Large circular "press to start" button with two staggered ripple rings.
/// Used for the Start Trip action in the driver dashboard and trip detail.
class PulsingStartButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final Color color;
  final IconData icon;

  const PulsingStartButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.label = 'START TRIP',
    this.color = const Color(0xFF16A34A),
    this.icon = Icons.play_arrow_rounded,
  });

  @override
  State<PulsingStartButton> createState() => _PulsingStartButtonState();
}

class _PulsingStartButtonState extends State<PulsingStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Ring 1 — leads
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;

  // Ring 2 — follows with offset
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;

  static const _btnSize = 76.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ring1Scale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
    _ring1Opacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));

    _ring2Scale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
    _ring2Opacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.isLoading ? null : widget.onTap,
          child: SizedBox(
            width: _btnSize * 1.8,
            height: _btnSize * 1.8,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  // Ring 1
                  Transform.scale(
                    scale: _ring1Scale.value,
                    child: Opacity(
                      opacity: _ring1Opacity.value,
                      child: _ring(_btnSize),
                    ),
                  ),
                  // Ring 2
                  Transform.scale(
                    scale: _ring2Scale.value,
                    child: Opacity(
                      opacity: _ring2Opacity.value,
                      child: _ring(_btnSize),
                    ),
                  ),
                  // Main button
                  Container(
                    width: _btnSize,
                    height: _btnSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 38,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      );
}
