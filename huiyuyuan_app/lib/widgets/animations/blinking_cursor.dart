import 'package:flutter/material.dart';

/// Blinking cursor used for typing effects.
class BlinkingCursor extends StatefulWidget {
  final double height;
  final double? fontSize;
  final Color baseColor;

  const BlinkingCursor({
    super.key,
    this.height = 16.0,
    this.fontSize,
    this.baseColor = const Color(0xFF2ECC71),
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 0.0 -> 0.5 visible, 0.5 -> 1.0 hidden.
        final isVisible = _controller.value < 0.5;

        return Transform.translate(
          offset: const Offset(4, 3),
          child: Container(
            width: 2.0,
            height: widget.fontSize ?? widget.height,
            decoration: BoxDecoration(
              color: isVisible ? widget.baseColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
