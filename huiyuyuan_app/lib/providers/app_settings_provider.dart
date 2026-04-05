/// 汇玉源 - 应用设置 Provider
///
/// 功能:
/// - 语言设置（简体中文/English/繁體中文）
/// - 深色模式（深色/浅色/跟随系统）
/// - 缓存管理
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/translator_global.dart';

/// 支持的语言列表
enum AppLanguage {
  zhCN('简体中文', 'zh_CN'),
  en('English', 'en'),
  zhTW('繁體中文', 'zh_TW');

  final String label;
  final String code;
  const AppLanguage(this.label, this.code);
}

/// 主题模式
enum AppThemeMode {
  dark('深色模式', 'dark'),
  light('浅色模式', 'light'),
  system('跟随系统', 'system');

  final String label;
  final String code;
  const AppThemeMode(this.label, this.code);
}

/// 应用设置状态
class AppSettings {
  final AppLanguage language;
  final AppThemeMode themeMode;
  final double cacheSize; // MB

  const AppSettings({
    this.language = AppLanguage.zhCN,
    this.themeMode = AppThemeMode.dark,
    this.cacheSize = 0.0,
  });

  AppSettings copyWith({
    AppLanguage? language,
    AppThemeMode? themeMode,
    double? cacheSize,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      cacheSize: cacheSize ?? this.cacheSize,
    );
  }
}

/// 应用设置 Notifier
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('app_language') ?? 'zh_CN';
      final themeCode = prefs.getString('app_theme') ?? 'dark';

      final lang = _parseLanguage(langCode);
      final theme = AppThemeMode.values.firstWhere(
        (t) => t.code == themeCode,
        orElse: () => AppThemeMode.dark,
      );

      // 估算缓存大小（模拟）
      final cacheSize = prefs.getDouble('cache_size') ?? _estimateCacheSize();

      // 同步全局翻译器语言
      TranslatorGlobal.updateLanguage(lang);
      state = AppSettings(
        language: lang,
        themeMode: theme,
        cacheSize: cacheSize,
      );
    } catch (_) {
      // 如果读取失败，使用默认值
      state = AppSettings(cacheSize: _estimateCacheSize());
    }
  }

  /// 估算缓存大小
  double _estimateCacheSize() {
    // 根据运行时长模拟缓存增长
    final now = DateTime.now();
    final base = 3.5 + (now.day * 0.3) + (now.hour * 0.05);
    return double.parse(base.toStringAsFixed(1));
  }

  AppLanguage _parseLanguage(String rawCode) {
    final normalized = rawCode.trim();
    switch (normalized) {
      case 'en':
      case 'en_US':
      case 'en-Us':
      case 'en-US':
        return AppLanguage.en;
      case 'zh_TW':
      case 'zhTW':
      case 'zh-TW':
      case 'tw':
      case 'zh_HK':
      case 'zh-HK':
        return AppLanguage.zhTW;
      case 'zh_CN':
      case 'zhCN':
      case 'zh-CN':
      case 'cn':
      default:
        return AppLanguage.zhCN;
    }
  }

  /// 设置语言
  Future<void> setLanguage(AppLanguage language) async {
    // 同步全局翻译器语言，确保登录页面也跟随切换
    TranslatorGlobal.updateLanguage(language);
    state = state.copyWith(language: language);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language.code);
    } catch (_) {}
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', mode.code);
    } catch (_) {}
  }

  /// 清除缓存
  Future<void> clearCache() async {
    state = state.copyWith(cacheSize: 0.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cache_size', 0.0);
      // 清除图片缓存等可以在这里添加
    } catch (_) {}
  }

  /// 刷新缓存大小
  void refreshCacheSize() {
    state = state.copyWith(cacheSize: _estimateCacheSize());
  }
}

/// 全局设置 Provider
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});
