import 'package:flutter/material.dart';

/// 🌊 优雅的波浪式跳动点（Loading/Thinking 动画）
/// 包含垂直位移、透明度和缩放三种动画效果，营造呼吸感与流动性。
class TypingIndicator extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final Duration duration;

  const TypingIndicator({
    super.key,
    this.dotColor = const Color(0xFF2ECC71), // 默认翡翠绿
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
    )..repeat(); // 🔁 无限循环
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
        // 每个点延迟启动，形成波浪效果
        // 0.0 -> 0.0, 0.2 -> 0.2, 0.4 -> 0.4
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
    // 使用 Interval 控制动画在时间轴上的起止点
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(beginInterval, endInterval, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 📉 动画值：0 -> 1 -> 0 (Bell Curve)
        final value = animation.value;

        // y轴位移：向上浮动
        final translateY = -6.0 * _bellCurve(value);

        // 透明度：0.3 -> 1.0 -> 0.3
        final opacity = 0.3 + (0.7 * _bellCurve(value));

        // 缩放：0.8 -> 1.1 -> 0.8 (微弹)
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

  /// 🔔 钟形曲线函数：输入 0->1，输出 0->1->0
  /// 使得动画在中间达到峰值
  double _bellCurve(double x) {
    return 1.0 - (2.0 * x - 1.0).abs();
  }
}
