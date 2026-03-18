/// 汇玉源 - 主题定义
/// 包含亮色主题和暗色主题
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// 汇玉源主题配置
class JewelryTheme {
  JewelryTheme._();

  // ============ 亮色主题 ============
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // 颜色方案
        colorScheme: ColorScheme.light(
          primary: JewelryColors.primary,
          onPrimary: JewelryColors.textOnPrimary,
          secondary: JewelryColors.gold,
          onSecondary: Colors.black87,
          surface: JewelryColors.surface,
          onSurface: JewelryColors.textPrimary,
          error: JewelryColors.error,
          onError: Colors.white,
        ),

        // 脚手架背景
        scaffoldBackgroundColor: JewelryColors.background,

        // AppBar主题
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: JewelryColors.primary,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.lgAll,
          ),
          color: JewelryColors.card,
          shadowColor: JewelryColors.shadowLight,
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: JewelryColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: JewelryRadius.mdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: JewelryColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: JewelryColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: JewelryRadius.mdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: JewelryColors.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide:
                const BorderSide(color: JewelryColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: const BorderSide(color: JewelryColors.error, width: 1),
          ),
          hintStyle: TextStyle(color: JewelryColors.textHint, fontSize: 14),
          labelStyle: const TextStyle(color: JewelryColors.textSecondary),
        ),

        // 分隔线
        dividerTheme: const DividerThemeData(
          color: JewelryColors.divider,
          thickness: 1,
          space: 1,
        ),

        // 芯片主题
        chipTheme: ChipThemeData(
          backgroundColor: JewelryColors.primary.withOpacity(0.1),
          labelStyle: const TextStyle(
            color: JewelryColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.roundAll,
          ),
        ),

        // 底部导航栏
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: JewelryColors.primary,
          unselectedItemColor: JewelryColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // 浮动按钮
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: JewelryColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.xlAll,
          ),
          titleTextStyle: const TextStyle(
            color: JewelryColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // SnackBar主题
        snackBarTheme: SnackBarThemeData(
          backgroundColor: JewelryColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.mdAll,
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // 字体主题 - 使用 Google Fonts
        textTheme: GoogleFonts.notoSansScTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
            displaySmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),

        // 页面过渡动画
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      );

  // ============ 暗色主题 ============
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // 颜色方案
        colorScheme: ColorScheme.dark(
          primary: JewelryColors.primaryLight,
          onPrimary: Colors.white,
          secondary: JewelryColors.gold,
          onSecondary: Colors.black,
          surface: const Color(0xFF1E1E2E),
          onSurface: const Color(0xFFE8E8EC),
          error: JewelryColors.error,
          onError: Colors.white,
        ),

        // 脚手架背景
        scaffoldBackgroundColor: const Color(0xFF121218),

        // AppBar主题
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A28),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.lgAll,
          ),
          color: const Color(0xFF252532),
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: JewelryColors.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: JewelryRadius.mdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: JewelryColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side:
                const BorderSide(color: JewelryColors.primaryLight, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: JewelryRadius.mdAll,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: JewelryColors.primaryLight,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 输入框主题 - 暗色模式完整定义
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3A),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: const BorderSide(color: Color(0xFF3A3A4A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide:
                const BorderSide(color: JewelryColors.primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: JewelryRadius.mdAll,
            borderSide: const BorderSide(color: JewelryColors.error, width: 1),
          ),
          hintStyle: const TextStyle(color: Color(0xFF8888A0), fontSize: 14),
          labelStyle: const TextStyle(color: Color(0xFFAAAAAC)),
        ),

        // 分隔线
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2E2E3E),
          thickness: 1,
          space: 1,
        ),

        // 芯片主题
        chipTheme: ChipThemeData(
          backgroundColor: JewelryColors.primaryLight.withOpacity(0.15),
          labelStyle: const TextStyle(
            color: JewelryColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.roundAll,
          ),
        ),

        // 底部导航栏
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A28),
          selectedItemColor: JewelryColors.primaryLight,
          unselectedItemColor: Color(0xFF666680),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // 浮动按钮
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: JewelryColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 6,
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF252532),
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.xlAll,
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFFE8E8EC),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // SnackBar主题
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2A2A3A),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: JewelryRadius.mdAll,
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // 字体主题 - 使用 Google Fonts
        textTheme: GoogleFonts.notoSansScTextTheme(
          ThemeData.dark().textTheme,
        ),

        // 页面过渡动画
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      );
}

/// 主题扩展 - 自定义样式与颜色自适应
extension ThemeExtension on BuildContext {
  /// 获取是否为暗色模式
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// 获取主渐变
  LinearGradient get primaryGradient => JewelryColors.primaryGradient;

  /// 获取金色渐变
  LinearGradient get goldGradient => JewelryColors.goldGradient;

  /// 获取玻璃态渐变
  LinearGradient get glassGradient => JewelryColors.glassGradient;

  // ============ 主题自适应颜色 ============
  /// 自适应背景色
  Color get adaptiveBackground =>
      isDark ? JewelryColors.darkBackground : JewelryColors.background;

  /// 自适应表面色（卡片背景）
  Color get adaptiveSurface =>
      isDark ? JewelryColors.darkSurface : JewelryColors.surface;

  /// 自适应卡片色
  Color get adaptiveCard =>
      isDark ? JewelryColors.darkCard : JewelryColors.card;

  /// 自适应分割线色
  Color get adaptiveDivider =>
      isDark ? JewelryColors.darkDivider : JewelryColors.divider;

  /// 自适应主文字色
  Color get adaptiveTextPrimary =>
      isDark ? JewelryColors.darkTextPrimary : JewelryColors.textPrimary;

  /// 自适应次要文字色
  Color get adaptiveTextSecondary =>
      isDark ? JewelryColors.darkTextSecondary : JewelryColors.textSecondary;

  /// 自适应提示文字色
  Color get adaptiveTextHint =>
      isDark ? JewelryColors.darkTextHint : JewelryColors.textHint;
}
