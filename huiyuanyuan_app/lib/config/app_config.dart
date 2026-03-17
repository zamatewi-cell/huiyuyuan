/// 汇玉源应用配置
library;

import 'package:flutter/foundation.dart';
import 'secrets.dart';

class AppConfig {
  // OpenRouter AI API 配置 - 从 Secrets 读取
  static String get openRouterApiKey => Secrets.openRouterApiKey;
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterModel = 'nvidia/nemotron-nano-12b-v2-vl:free';
  static const String openRouterSiteUrl = 'https://huiyuanyuan.local';
  static const String openRouterAppName = '汇玉源';

  // 应用信息
  static const String appName = '汇玉源';
  static const String appVersion = '3.0.0';
  static const String appDescription = '珠宝智能交易平台';

  // 主题色
  static const int primaryColorValue = 0xFF2E8B57; // 海绿色
  static const int accentColorValue = 0xFFFFD700; // 金色

  // 管理员配置
  static const String adminPhone = '18937766669';

  // 凭据仅在 Debug 模式下可用；Release 构建通过 --dart-define 注入或后端验证
  static String get adminPassword =>
      const String.fromEnvironment('ADMIN_PASSWORD',
          defaultValue: kDebugMode ? 'admin123' : '');

  static String get adminAuthCode =>
      const String.fromEnvironment('ADMIN_AUTH_CODE',
          defaultValue: kDebugMode ? '8888' : '');

  static String get operatorDefaultPassword =>
      const String.fromEnvironment('OPERATOR_PASSWORD',
          defaultValue: kDebugMode ? 'op123456' : '');

  // API 超时设置
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000;

  // 调试模式
  static const bool isDebugMode = true;
}
