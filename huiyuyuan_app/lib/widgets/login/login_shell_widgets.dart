import 'dart:math' as math;
import '../../l10n/translator_global.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/colors.dart';

class LoginAnimatedBackground extends ConsumerWidget {
  const LoginAnimatedBackground({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final phase = animation.value * 2 * math.pi;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(phase) * 0.72, -1),
              end: Alignment(-math.sin(phase) * 0.72, 1),
              colors: const [
                JewelryColors.jadeBlack,
                JewelryColors.deepJade,
                JewelryColors.jadeInk,
                Color(0xFF12382D),
              ],
              stops: const [0.0, 0.38, 0.72, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _LoginBackgroundPainter(animation.value),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final emeraldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          JewelryColors.primary.withOpacity(0.28),
          JewelryColors.primary.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.18, size.height * 0.16),
          radius: size.shortestSide * 0.66,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.16),
      size.shortestSide * 0.66,
      emeraldGlow,
    );

    final champagneGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          JewelryColors.champagneGold.withOpacity(0.2),
          JewelryColors.goldDark.withOpacity(0.055),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.82),
          radius: size.shortestSide * 0.62,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.82),
      size.shortestSide * 0.62,
      champagneGlow,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = JewelryColors.champagneGold.withOpacity(0.055);

    for (var i = 0; i < 7; i++) {
      final yBase = size.height * (0.16 + i * 0.13);
      final path = Path()..moveTo(-size.width * 0.18, yBase);
      for (var x = -size.width * 0.18; x <= size.width * 1.18; x += 28) {
        final wobble = math.sin((x / size.width * 2.4 * math.pi) +
                phase * 2 * math.pi +
                i * 0.65) *
            (18 + i * 2);
        path.lineTo(x, yBase + wobble);
      }
      canvas.drawPath(path, wavePaint);
    }

    final dustPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 26; i++) {
      final x = (size.width * ((i * 0.173 + phase * 0.035) % 1.0));
      final y = size.height * ((i * 0.317 + 0.11) % 1.0);
      final color = i.isEven
          ? JewelryColors.emeraldGlow.withOpacity(0.16)
          : JewelryColors.champagneGold.withOpacity(0.12);
      dustPaint.color = color;
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.8 : 1.15, dustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class LoginDecorations extends ConsumerWidget {
  const LoginDecorations({
    super.key,
    required this.size,
    required this.animation,
  });

  final Size size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Positioned(
              top: -80 + animation.value,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      JewelryColors.primary.withOpacity(0.3),
                      JewelryColors.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Positioned(
              bottom: -100 - animation.value,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      JewelryColors.gold.withOpacity(0.2),
                      JewelryColors.gold.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: size.height * 0.3,
          right: 30,
          child: _LoginFloatingJewel(
            animation: animation,
            color: JewelryColors.emeraldGlow,
            size: 15,
          ),
        ),
        Positioned(
          top: size.height * 0.6,
          left: 40,
          child: _LoginFloatingJewel(
            animation: animation,
            color: JewelryColors.champagneGold,
            size: 10,
          ),
        ),
        Positioned(
          bottom: size.height * 0.25,
          right: 60,
          child: _LoginFloatingJewel(
            animation: animation,
            color: JewelryColors.primary,
            size: 12,
          ),
        ),
      ],
    );
  }
}

class _LoginFloatingJewel extends ConsumerWidget {
  const _LoginFloatingJewel({
    required this.animation,
    required this.color,
    required this.size,
  });

  final Animation<double> animation;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value * 0.5),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  color.withOpacity(0.86),
                  color.withOpacity(0.18),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.42),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LoginBrandLogo extends ConsumerWidget {
  const LoginBrandLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 420;
    final wide = screenWidth >= 1280;
    final logoSize = compact
        ? 88.0
        : wide
            ? 112.0
            : 100.0;
    final ringSize = logoSize * 0.8;
    final titleSize = compact
        ? 32.0
        : wide
            ? 40.0
            : 36.0;

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: JewelryColors.emeraldLusterGradient,
            boxShadow: [
              BoxShadow(
                color: JewelryColors.emeraldGlow.withOpacity(0.22),
                blurRadius: 38,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: logoSize * 0.9,
                height: logoSize * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.18),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                    width: 7,
                  ),
                ),
              ),
              ..._buildJadeBeads(logoSize),
              Icon(
                Icons.diamond_outlined,
                color: JewelryColors.champagneGold.withOpacity(0.96),
                size: logoSize * 0.34,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) =>
              JewelryColors.champagneGradient.createShader(bounds),
          child: Text(
            TranslatorGlobal.instance.translate('app_name'),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: compact ? 3.2 : 4.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          TranslatorGlobal.instance.translate('app_slogan'),
          style: TextStyle(
            fontSize: 14,
            color: JewelryColors.jadeMist.withOpacity(0.68),
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildJadeBeads(double logoSize) {
    final beads = <Widget>[];
    const beadCount = 8;
    final radius = logoSize * 0.36;
    final beadSize = logoSize * 0.1;
    final center = logoSize / 2;

    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * math.pi - math.pi / 2;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      beads.add(
        Positioned(
          left: center + x - beadSize / 2,
          top: center + y - beadSize / 2,
          child: Container(
            width: beadSize,
            height: beadSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: i.isEven
                    ? const [Color(0xFFFFFAE8), JewelryColors.champagneGold]
                    : const [JewelryColors.emeraldGlow, JewelryColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.25),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return beads;
  }
}

class LoginCardShell extends ConsumerWidget {
  const LoginCardShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.child,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.max(
      320.0,
      math.min(screenWidth - 32, screenWidth >= 1200 ? 420.0 : 380.0),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.all(screenWidth >= 1200 ? 32 : 28),
          decoration: BoxDecoration(
            gradient: JewelryColors.liquidGlassGradient,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: JewelryShadows.liquidGlass,
          ),
          child: Column(
            children: [
              LoginTabSelector(
                selectedTab: selectedTab,
                onTabChanged: onTabChanged,
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class LoginTabSelector extends ConsumerWidget {
  const LoginTabSelector({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: JewelryColors.deepJade.withOpacity(0.64),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LoginTabButton(
              label: TranslatorGlobal.instance.translate('login_tab_customer'),
              icon: Icons.person_outline,
              selected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _LoginTabButton(
              label: TranslatorGlobal.instance.translate('role_operator'),
              icon: Icons.support_agent,
              selected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
          Expanded(
            child: _LoginTabButton(
              label: TranslatorGlobal.instance.translate('login_tab_admin'),
              icon: Icons.admin_panel_settings,
              selected: selectedTab == 2,
              onTap: () => onTabChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTabButton extends ConsumerWidget {
  const _LoginTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: selected ? JewelryColors.emeraldLusterGradient : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: JewelryColors.emeraldGlow.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? JewelryColors.jadeBlack
                    : JewelryColors.jadeMist.withOpacity(0.58),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected
                      ? JewelryColors.jadeBlack
                      : JewelryColors.jadeMist.withOpacity(0.58),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginFooter extends ConsumerWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: JewelryColors.champagneGold.withOpacity(0.38),
            ),
            const SizedBox(width: 6),
            Text(
              TranslatorGlobal.instance.translate('login_security_footer'),
              style: TextStyle(
                fontSize: 12,
                color: JewelryColors.jadeMist.withOpacity(0.42),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          TranslatorGlobal.instance.translate('compliance_copyright'),
          style: TextStyle(
            fontSize: 11,
            color: JewelryColors.jadeMist.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
