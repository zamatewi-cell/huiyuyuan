import 'package:flutter/material.dart';

/// Wave-style typing indicator for loading or thinking states.
///
/// The dots animate with vertical movement, opacity, and scale changes.
class TypingIndicator extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final Duration duration;

  const TypingIndicator({
    super.key,
    this.dotColor = const Color(0xFF2ECC71),
    this.dotSize = 8.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        // Stagger each dot to form a wave.
        final begin = index * 0.2;
        final end = begin + 0.6;

        return _AnimatedDot(
          controller: _controller,
          color: widget.dotColor,
          size: widget.dotSize,
          beginInterval: begin,
          endInterval: end,
        );
      }),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double size;
  final double beginInterval;
  final double endInterval;

  const _AnimatedDot({
    required this.controller,
    required this.color,
    required this.size,
    required this.beginInterval,
    required this.endInterval,
  });

  @override
  Widget build(BuildContext context) {
    // Scope each dot to its own interval on the shared timeline.
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(beginInterval, endInterval, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Value progresses 0 -> 1 -> 0 as a bell curve.
        final value = animation.value;

        // Vertical lift.
        final translateY = -6.0 * _bellCurve(value);

        // Opacity pulse.
        final opacity = 0.3 + (0.7 * _bellCurve(value));

        // Subtle scale pulse.
        final scale = 0.8 + (0.3 * _bellCurve(value));

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bell-curve helper that peaks in the middle of the interval.
  double _bellCurve(double x) {
    return 1.0 - (2.0 * x - 1.0).abs();
  }
}
