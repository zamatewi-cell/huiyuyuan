/// 汇玉源 - 颜色系统
/// 设计风格: 高端珠宝 + 玻璃态 + 渐变色
library;

import 'package:flutter/material.dart';

/// 品牌色彩系统
class JewelryColors {
  JewelryColors._();

  // ============ 品牌主色 ============
  /// 翡翠绿 - 品牌主色
  static const Color primary = Color(0xFF2E8B57);
  static const Color primaryLight = Color(0xFF3CB371);
  static const Color primaryDark = Color(0xFF228B22);

  /// 金色 - 强调色
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE44D);
  static const Color goldDark = Color(0xFFDAA520);

  /// 别名 - 方便直接引用
  static const Color primaryGreen = primary;

  // ============ 材质色彩 ============
  /// 和田玉色系
  static const Color hetianYu = Color(0xFFF5F5DC);
  static const Color hetianYuDeep = Color(0xFFE8E4C9);

  /// 翡翠色系
  static const Color jadeite = Color(0xFF50C878);
  static const Color jadeiteDeep = Color(0xFF32CD32);

  /// 南红玛瑙色系
  static const Color nanHong = Color(0xFFFF6347);
  static const Color nanHongDeep = Color(0xFFDC143C);

  /// 紫水晶色系
  static const Color amethyst = Color(0xFF9370DB);
  static const Color amethystDeep = Color(0xFF8A2BE2);

  // ============ 渐变色 ============
  /// 主渐变 - 翡翠绿
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF3CB371), Color(0xFF50C878)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 金色渐变 - 奢华感
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 钻石光辉渐变
  static const LinearGradient diamondGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE8E8E8), Color(0xFFC0C0C0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 暗色渐变背景
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 玻璃态背景渐变
  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.25),
      Colors.white.withOpacity(0.15),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 卡片背景渐变
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ 语义色彩 ============
  /// 成功 - 翠绿色
  static const Color success = Color(0xFF28A745);

  /// 警告 - 金橙色（WCAG AA 对比度 ≥ 4.5:1）
  static const Color warning = Color(0xFFE09200);

  /// 错误 - 珊瑚红
  static const Color error = Color(0xFFDC3545);

  /// 信息 - 蓝色
  static const Color info = Color(0xFF17A2B8);

  /// 价格 - 红色
  static const Color price = Color(0xFFE53935);

  // ============ 中性色 ============
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE9ECEF);

  /// 文字颜色
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFF8B95A1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============ 阴影色 ============
  static Color shadowLight = Colors.black.withOpacity(0.06);
  static Color shadowMedium = Colors.black.withOpacity(0.12);
  static Color shadowDark = Colors.black.withOpacity(0.2);
  static Color shadowPrimary = primary.withOpacity(0.3);
  static Color shadowGold = gold.withOpacity(0.3);

  // ============ 工具方法 ============
  /// 获取材质对应颜色
  static Color getMaterialColor(String material) {
    switch (material) {
      case '和田玉':
        return hetianYu;
      case '缅甸翡翠':
      case '翡翠':
        return jadeite;
      case '南红玛瑙':
      case '南红':
        return nanHong;
      case '紫水晶':
        return amethyst;
      case '碧玉':
        return primaryDark;
      case '蜜蜡':
        return gold;
      case '黄金':
        return goldDark;
      case '红宝石':
        return nanHong;
      case '蓝宝石':
        return info;
      default:
        return primary;
    }
  }

  /// 获取材质渐变
  static LinearGradient getMaterialGradient(String material) {
    final baseColor = getMaterialColor(material);
    return LinearGradient(
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============ 暗色模式色板 ============
  /// 暗色模式背景色
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkCard = Color(0xFF252532);
  static const Color darkDivider = Color(0xFF2E2E3E);

  /// 暗色模式文字颜色
  static const Color darkTextPrimary = Color(0xFFE8E8EC);
  static const Color darkTextSecondary = Color(0xFF9999AC);
  static const Color darkTextHint = Color(0xFF8888A0);
}

/// 阴影预设
class JewelryShadows {
  JewelryShadows._();

  /// 浅阴影 - 卡片
  static List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// 中等阴影 - 悬浮
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: JewelryColors.primary.withOpacity(0.05),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  /// 深阴影 - 弹窗
  static List<BoxShadow> heavy = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
    BoxShadow(
      color: JewelryColors.primary.withOpacity(0.1),
      blurRadius: 60,
      offset: const Offset(0, 30),
    ),
  ];

  /// 金色发光阴影
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: JewelryColors.gold.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  /// 翠绿发光阴影
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: JewelryColors.primary.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

/// 边框半径预设
class JewelryRadius {
  JewelryRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double round = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get roundAll => BorderRadius.circular(round);
}

/// 间距预设
class JewelrySpacing {
  JewelrySpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}
