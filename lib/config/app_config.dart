/// 汇玉源应用配置
library;

import 'secrets.dart';

class AppConfig {
  // DeepSeek AI API 配置 - 从 Secrets 读取
  static String get deepseekApiKey => Secrets.deepseekApiKey;
  static const String deepseekBaseUrl = 'https://api.deepseek.com';

  // Google Gemini API 配置 - 从 Secrets 读取
  static String get geminiApiKey => Secrets.geminiApiKey;
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.0-flash-exp';

  // 应用信息
  static const String appName = '汇玉源';
  static const String appVersion = '3.0.0';
  static const String appDescription = '珠宝智能交易平台';

  // 主题色
  static const int primaryColorValue = 0xFF2E8B57; // 海绿色
  static const int accentColorValue = 0xFFFFD700; // 金色

  // 管理员配置
  static const String adminPhone = '18937766669';
  static const String adminPassword = 'admin123';
  static const String adminAuthCode = '8888';

  // 操作员默认密码
  static const String operatorDefaultPassword = 'op123456';

  // API 超时设置
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000;

  // 调试模式
  static const bool isDebugMode = true;
}
