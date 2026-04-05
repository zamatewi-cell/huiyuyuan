library;

import 'package:flutter/material.dart';

import '../../themes/colors.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final int count;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: iconColor, size: size),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: JewelryColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
