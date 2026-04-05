import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/colors.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

class LoginAnimatedBackground extends ConsumerWidget {
  const LoginAnimatedBackground({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(animation.value * 2 * math.pi),
                math.sin(animation.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos(animation.value * 2 * math.pi + math.pi),
                math.sin(animation.value * 2 * math.pi + math.pi),
              ),
              colors: const [
                Color(0xFF0D1B2A),
                Color(0xFF1B263B),
                Color(0xFF1F4037),
                Color(0xFF0D1B2A),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
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
            color: JewelryColors.jadeite,
            size: 15,
          ),
        ),
        Positioned(
          top: size.height * 0.6,
          left: 40,
          child: _LoginFloatingJewel(
            animation: animation,
            color: JewelryColors.gold,
            size: 10,
          ),
        ),
        Positioned(
          bottom: size.height * 0.25,
          right: 60,
          child: _LoginFloatingJewel(
            animation: animation,
            color: JewelryColors.amethyst,
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
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
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
            gradient: JewelryColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: JewelryColors.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 8,
                  ),
                ),
              ),
              ..._buildJadeBeads(logoSize),
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: logoSize * 0.32,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, JewelryColors.gold],
          ).createShader(bounds),
          child: Text(
            ref.tr('app_name'),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: compact ? 2.5 : 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ref.tr('app_slogan'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
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
              color: i.isEven ? JewelryColors.hetianYu : JewelryColors.jadeite,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 3,
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
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.all(screenWidth >= 1200 ? 32 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LoginTabButton(
              label: 'login_tab_customer'.tr,
              icon: Icons.person_outline,
              selected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _LoginTabButton(
              label: ref.tr('role_operator'),
              icon: Icons.support_agent,
              selected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
          Expanded(
            child: _LoginTabButton(
              label: 'login_tab_admin'.tr,
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
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: selected ? JewelryColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w600,
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
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              'login_security_footer'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ref.tr('compliance_copyright'),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
