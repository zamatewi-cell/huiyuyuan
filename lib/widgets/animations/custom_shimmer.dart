import 'package:flutter/material.dart';

/// ✨ 企业级渐变骨架屏 (CustomShimmer)
///
/// 实现高质量的“流光扫过”效果，模拟加载状态。
/// - 支持透明度脉冲 (Fade)
/// - 支持线性渐变扫光 (Gradient Wipe)
/// - 使用 ShaderMask 高效渲染，无侵入性。
class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const CustomShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFF5F5F5), // 浅色背景默认
    this.highlightColor = const Color(0xFFFFFFFF), // 亮光高亮
    this.enabled = true,
  });

  /// 使用当前主题颜色的 Shimmer（自动适配深色/浅色模式）
  /// - 深色模式：#333333 -> #444444
  /// - 浅色模式：#EEEEEE -> #FFFFFF
  factory CustomShimmer.adaptive(
    BuildContext context, {
    required Widget child,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomShimmer(
      baseColor: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A4A) : Colors.white,
      enabled: enabled,
      child: child,
    );
  }

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 计算渐变位置：-0.5 -> 1.5 模拟扫过整个区域
        final offset = _controller.value * 2 - 0.5;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // 线性渐变：基础色 -> 高亮 -> 基础色
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + offset, 0.0),
              end: Alignment(1.0 + offset, 0.0),
              transform: const GradientRotation(0.2), // 微倾斜扫光
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
