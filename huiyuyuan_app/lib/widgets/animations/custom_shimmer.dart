import 'package:flutter/material.dart';

/// Gradient shimmer used for loading placeholders.
///
/// This widget provides a lightweight sweep animation over any child.
/// - supports adaptive light and dark palettes
/// - uses a linear gradient wipe
/// - renders efficiently with [ShaderMask]
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
    this.baseColor = const Color(0xFFF5F5F5),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.enabled = true,
  });

  /// Creates a shimmer that follows the current brightness mode.
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
        // Sweep the highlight across the child from left to right.
        final offset = _controller.value * 2 - 0.5;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Fade from base -> highlight -> base for a smooth wipe.
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + offset, 0.0),
              end: Alignment(1.0 + offset, 0.0),
              transform: const GradientRotation(0.2),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
