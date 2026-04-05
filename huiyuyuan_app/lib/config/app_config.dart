library;

import 'package:flutter/foundation.dart';

import 'local_debug_config.dart';
import 'secrets.dart';

class AppConfig {
  static String get dashScopeApiKey {
    final injected = Secrets.dashScopeApiKey.trim();
    if (injected.isNotEmpty) {
      return injected;
    }

    final legacyInjected = Secrets.openRouterApiKey.trim();
    if (legacyInjected.isNotEmpty) {
      return legacyInjected;
    }

    return ((LocalDebugConfig.instance.getString('DASHSCOPE_API_KEY') ??
                LocalDebugConfig.instance.getString('OPENROUTER_API_KEY')) ??
            '')
        .trim();
  }

  static String get dashScopeApiKeySource {
    if (Secrets.dashScopeApiKey.trim().isNotEmpty) {
      return '--dart-define:DASHSCOPE_API_KEY';
    }

    if (Secrets.openRouterApiKey.trim().isNotEmpty) {
      return '--dart-define:OPENROUTER_API_KEY';
    }

    return LocalDebugConfig.instance.loadedFromPath ?? 'missing';
  }

  static String? get dashScopeApiKeyIssue {
    final configLoadError = LocalDebugConfig.instance.loadError?.trim();
    if (configLoadError != null && configLoadError.isNotEmpty) {
      return '.env.json parse failed: $configLoadError';
    }

    final key = dashScopeApiKey.trim();
    if (key.isEmpty) {
      return 'DASHSCOPE_API_KEY missing';
    }
    if (key.contains('YOUR_') ||
        key.contains('DashScope API Key') ||
        key.contains('Qwen API Key') ||
        key.contains('千问 API Key')) {
      return 'DASHSCOPE_API_KEY is still placeholder text';
    }
    if (key.startsWith('sk-or-')) {
      return 'DASHSCOPE_API_KEY appears to be an OpenRouter key';
    }
    if (!key.startsWith('sk-')) {
      return 'DASHSCOPE_API_KEY must start with sk-';
    }
    return null;
  }

  static bool get hasValidDashScopeApiKey => dashScopeApiKeyIssue == null;

  static const String dashScopeBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String dashScopeModel = 'qwen-plus';

  static const String appName = '汇玉源';
  static const String appVersion = '3.0.3';
  static const int appBuildNumber = 5;
  static const String appDescription = '珠宝智能交易平台';

  static const int primaryColorValue = 0xFF2E8B57;
  static const int accentColorValue = 0xFFFFD700;

  static String get adminPhone => const String.fromEnvironment(
        'ADMIN_PHONE',
        defaultValue: kReleaseMode ? '' : '18937766669',
      );

  static String get adminPassword => const String.fromEnvironment(
        'ADMIN_PASSWORD',
        defaultValue: kReleaseMode ? '' : 'admin123',
      );

  static String get adminAuthCode => const String.fromEnvironment(
        'ADMIN_AUTH_CODE',
        defaultValue: kReleaseMode ? '' : '8888',
      );

  static String get operatorDefaultPassword => const String.fromEnvironment(
        'OPERATOR_PASSWORD',
        defaultValue: kReleaseMode ? '' : 'op123456',
      );

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static bool get isDebugMode => kDebugMode;

  static bool get allowLocalCredentialFallback => !kReleaseMode;
}
