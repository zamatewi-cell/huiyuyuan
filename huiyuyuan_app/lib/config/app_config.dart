library;

import 'package:flutter/foundation.dart';

import 'local_debug_config.dart';
import 'secrets.dart';

class AppConfig {
  static const String _injectedEnableLocalCredentialFallback =
      String.fromEnvironment(
    'ENABLE_LOCAL_CREDENTIAL_FALLBACK',
    defaultValue: '',
  );
  static const String _injectedAdminPhone = String.fromEnvironment(
    'ADMIN_PHONE',
    defaultValue: '',
  );
  static const String _injectedAdminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: '',
  );
  static const String _injectedAdminAuthCode = String.fromEnvironment(
    'ADMIN_AUTH_CODE',
    defaultValue: '',
  );
  static const String _injectedOperatorPassword = String.fromEnvironment(
    'OPERATOR_PASSWORD',
    defaultValue: '',
  );

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
  static const String appVersion = '3.0.4';
  static const int appBuildNumber = 6;
  static const String appDescription = '珠宝智能交易平台';

  static const int primaryColorValue = 0xFF2E8B57;
  static const int accentColorValue = 0xFFFFD700;

  static String get adminPhone => _readStringSetting(
        injectedValue: _injectedAdminPhone,
        debugConfigKey: 'ADMIN_PHONE',
      );

  static String get adminPassword => _readStringSetting(
        injectedValue: _injectedAdminPassword,
        debugConfigKey: 'ADMIN_PASSWORD',
      );

  static String get adminAuthCode => _readStringSetting(
        injectedValue: _injectedAdminAuthCode,
        debugConfigKey: 'ADMIN_AUTH_CODE',
      );

  static String get operatorDefaultPassword => _readStringSetting(
        injectedValue: _injectedOperatorPassword,
        debugConfigKey: 'OPERATOR_PASSWORD',
      );

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static bool get isDebugMode => kDebugMode;

  static bool get allowLocalCredentialFallback =>
      !kReleaseMode &&
      _readBoolSetting(
        injectedValue: _injectedEnableLocalCredentialFallback,
        debugConfigKey: 'ENABLE_LOCAL_CREDENTIAL_FALLBACK',
      );

  static bool get allowLocalAdminCredentialFallback =>
      allowLocalCredentialFallback &&
      adminPhone.isNotEmpty &&
      adminPassword.isNotEmpty &&
      adminAuthCode.isNotEmpty;

  static bool get allowLocalOperatorCredentialFallback =>
      allowLocalCredentialFallback && operatorDefaultPassword.isNotEmpty;

  static String _readStringSetting({
    required String injectedValue,
    required String debugConfigKey,
  }) {
    final trimmedInjected = injectedValue.trim();
    if (trimmedInjected.isNotEmpty) {
      return trimmedInjected;
    }

    return (LocalDebugConfig.instance.getString(debugConfigKey) ?? '').trim();
  }

  static bool _readBoolSetting({
    required String injectedValue,
    required String debugConfigKey,
  }) {
    final normalized = injectedValue.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on';
    }

    return LocalDebugConfig.instance.getBool(debugConfigKey) ?? false;
  }
}
