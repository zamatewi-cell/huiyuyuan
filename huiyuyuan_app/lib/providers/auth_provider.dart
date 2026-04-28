// 汇玉源 - 认证状态管理
//
// 功能:
// - 管理员登录认证
// - 操作员登录认证
// - 登录状态持久化
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../l10n/translator_global.dart';
import 'cart_provider.dart';

// 认证状态Provider
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

// 认证状态Notifier
class AuthNotifier extends AsyncNotifier<UserModel?> {
  final _storage = StorageService();

  @override
  Future<UserModel?> build() async {
    // 初始化时检查本地存储的登录状态
    await _storage.init();
    final userData = await _storage.getUser();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  /// 管理员登录
  ///
  /// [phone] 手机号 (固定为 18925816362)
  /// [password] 密码
  /// [authCode] 管理员验证码
  Future<bool> loginAdmin(
      String phone, String password, String authCode) async {
    // 验证固定管理员账号

    // 尝试后端 API 认证
    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authLogin,
        data: {
          'username': phone,
          'password': password,
          'captcha': authCode,
          'type': 'admin',
        },
      );

      if (res.success && res.data != null) {
        final rawData = res.data;
        final data =
            (rawData is Map<String, dynamic>) ? rawData : <String, dynamic>{};
        final token = (data['token'] ?? '').toString();
        final refreshToken = (data['refresh_token'] ?? '').toString();
        final userRaw = data['user'];
        final userData = (userRaw is Map<String, dynamic>)
            ? Map<String, dynamic>.from(userRaw)
            : <String, dynamic>{};
        userData['token'] = token;

        try {
          await _storage.saveToken(token);
        } catch (_) {}
        try {
          if (refreshToken.isNotEmpty) {
            await _storage.saveRefreshToken(refreshToken);
          }
        } catch (_) {}
        try {
          await api.setToken(token);
        } catch (_) {}

        final user = UserModel.fromJson(userData);
        await _storage.saveUser(user.toJson());
        state = AsyncValue.data(user);
        // 登录后触发购物车云端同步（非阻塞）
        _syncCartAfterLogin();
        return true;
      }
      // API 返回失败时，Debug 模式今回退到本地凯据验证（包含测试环境 HTTP 400 的情况）
      if (AppConfig.allowLocalAdminCredentialFallback) {
        return _localAdminFallback(phone, password, authCode);
      }
      lastLoginError =
          _localizeAuthMessage(res.message, 'login_error_account_or_password');
      return false;
    } catch (e) {
      // 网络异常 也回退到本地 Debug 验证
      if (AppConfig.allowLocalAdminCredentialFallback) {
        return _localAdminFallback(phone, password, authCode);
      }
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  /// Debug 模式本地凭据验证（仅用于开发/测试，Release 不执行）
  Future<bool> _localAdminFallback(
      String phone, String password, String authCode) async {
    final expectedPhone = AppConfig.adminPhone;
    final expectedPassword = AppConfig.adminPassword;
    final expectedCode = AppConfig.adminAuthCode;

    if (phone != expectedPhone ||
        password != expectedPassword ||
        authCode != expectedCode) {
      lastLoginError = _t('login_error_account_or_password');
      return false;
    }

    final mockToken = 'debug-admin-${DateTime.now().microsecondsSinceEpoch}';
    final user = UserModel(
      id: 'admin-local',
      phone: phone,
      username: '管理员',
      userType: UserType.admin,
      token: mockToken,
    );
    try {
      await _storage.saveToken(mockToken);
    } catch (_) {}
    await _storage.saveUser(user.toJson());
    state = AsyncValue.data(user);
    _syncCartAfterLogin();
    return true;
  }

  /// 操作员登录
  ///
  /// [username] 操作员账号 (1-10号)
  /// [password] 密码
  Future<bool> loginOperator(String username, String password) async {
    // 解析操作员编号
    int? operatorNumber;

    // 支持多种格式: "1", "操作员1", "op1" 等
    // 排除负数格式（如 "-1"）：只允许非负号前缀
    final numMatch = RegExp(r'(?<![0-9-])(\d+)(?![0-9])').firstMatch(username);
    if (numMatch != null) {
      // 通过 int.tryParse 解析，并检查原始 username 中数字前不是 '-'
      final matchStart = numMatch.start;
      if (matchStart == 0 || username[matchStart - 1] != '-') {
        operatorNumber = int.tryParse(numMatch.group(1)!);
      }
    }

    // 验证操作员编号范围 (1-10)
    if (operatorNumber == null || operatorNumber < 1 || operatorNumber > 10) {
      return false;
    }

    // 尝试后端 API 认证
    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authLogin,
        data: {
          'username': username,
          'password': password,
          'type': 'operator',
        },
      );

      if (res.success && res.data != null) {
        final rawData = res.data;
        final data =
            (rawData is Map<String, dynamic>) ? rawData : <String, dynamic>{};
        final token = (data['token'] ?? '').toString();
        final refreshToken = (data['refresh_token'] ?? '').toString();
        final userRaw = data['user'];
        final userData = (userRaw is Map<String, dynamic>)
            ? Map<String, dynamic>.from(userRaw)
            : <String, dynamic>{};
        userData['token'] = token;

        try {
          await _storage.saveToken(token);
        } catch (_) {}
        try {
          if (refreshToken.isNotEmpty) {
            await _storage.saveRefreshToken(refreshToken);
          }
        } catch (_) {}
        try {
          await api.setToken(token);
        } catch (_) {}

        final user = UserModel.fromJson(userData);
        await _storage.saveUser(user.toJson());
        state = AsyncValue.data(user);
        // 登录后触发购物车云端同步（非阻塞）
        _syncCartAfterLogin();
        return true;
      }
      // API失败 —— Debug 下回退本地验证
      if (AppConfig.allowLocalOperatorCredentialFallback) {
        return _localOperatorFallback(operatorNumber, password);
      }
      lastLoginError =
          _localizeAuthMessage(res.message, 'login_error_account_or_password');
      return false;
    } catch (e) {
      if (AppConfig.allowLocalOperatorCredentialFallback) {
        return _localOperatorFallback(operatorNumber, password);
      }
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  /// Debug 模式操作员本地验证
  Future<bool> _localOperatorFallback(int opNum, String password) async {
    if (password != AppConfig.operatorDefaultPassword) {
      lastLoginError = _t('login_error_account_or_password');
      return false;
    }

    final mockToken =
        'debug-operator-$opNum-${DateTime.now().microsecondsSinceEpoch}';
    final user = UserModel(
      id: 'operator-local-$opNum',
      phone: '0000000000$opNum',
      username: '操作员$opNum号',
      userType: UserType.operator,
      token: mockToken,
      operatorNumber: opNum,
      permissions: const [
        'shop_radar',
        'ai_assistant',
        'orders',
        'inventory_read',
      ],
    );
    try {
      await _storage.saveToken(mockToken);
    } catch (_) {}
    await _storage.saveUser(user.toJson());
    state = AsyncValue.data(user);
    _syncCartAfterLogin();
    return true;
  }

  /// 登录结果错误信息（用于 UI 展示）
  String? lastLoginError;

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return AppStrings.get(TranslatorGlobal.currentLang, key, params: params);
  }

  bool _containsAny(String source, List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isNotEmpty && source.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  String _localizeAuthMessage(String? rawMessage, String fallbackKey) {
    final message = (rawMessage ?? '').trim();
    if (message.isEmpty) {
      return _t(fallbackKey);
    }

    final normalized = message.toLowerCase();
    if (_containsAny(message, ['验证码', '驗證碼']) &&
        _containsAny(message, ['错误', '錯誤', '无效', '無效', '不正确', '不正確'])) {
      return _t('login_error_wrong_code');
    }
    if (_containsAny(message, ['手机号', '手机号码', '手機號', '手機號碼']) &&
        _containsAny(message, ['未注册', '未註冊', '不存在'])) {
      return _t('login_error_phone_not_registered');
    }
    if (_containsAny(message, ['手机号', '手机号码', '手機號', '手機號碼']) &&
        _containsAny(message, ['已注册', '已註冊'])) {
      return _t('login_error_phone_registered');
    }
    if (_containsAny(message, ['协议', '協議']) ||
        normalized.contains('terms') ||
        normalized.contains('privacy')) {
      return _t('login_error_accept_agreement');
    }
    if (_containsAny(message, ['网络', '網路', '超时', '逾時']) ||
        normalized.contains('network') ||
        normalized.contains('timeout')) {
      return _t('login_error_network');
    }
    if (_containsAny(message, ['密码', '密碼', '账号', '帳號']) &&
        _containsAny(message, ['错误', '錯誤', '无效', '無效', '失败', '失敗'])) {
      return _t('login_error_account_or_password');
    }
    if (_containsAny(message, ['发送频繁', '發送頻繁']) ||
        normalized.contains('too many')) {
      return _t('please_retry_later');
    }

    return _t(fallbackKey);
  }

  Future<bool> _consumeAuthResponse(
    ApiResult<dynamic> res, {
    required String fallbackKey,
  }) async {
    if (res.success && res.data != null) {
      final rawData = res.data;
      final data =
          (rawData is Map<String, dynamic>) ? rawData : <String, dynamic>{};

      final token = (data['token'] ?? '').toString();
      final refreshToken = (data['refresh_token'] ?? '').toString();
      final userRaw = data['user'];
      final userData = (userRaw is Map<String, dynamic>)
          ? Map<String, dynamic>.from(userRaw)
          : <String, dynamic>{};
      userData['token'] = token;

      try {
        await _storage.saveToken(token);
      } catch (_) {}
      try {
        if (refreshToken.isNotEmpty) {
          await _storage.saveRefreshToken(refreshToken);
        }
      } catch (_) {}
      try {
        await ApiService().setToken(token);
      } catch (_) {}

      final user = UserModel.fromJson(userData);
      await _storage.saveUser(user.toJson());
      state = AsyncValue.data(user);
      _syncCartAfterLogin();
      return true;
    }

    lastLoginError = _localizeAuthMessage(res.message, fallbackKey);
    return false;
  }

  /// 用户验证码登录
  Future<bool> loginCustomerWithSms(String phone, String authCode) async {
    lastLoginError = null;
    if (phone.isEmpty || authCode.isEmpty) {
      lastLoginError = _t('login_error_phone_or_code_required');
      return false;
    }

    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authVerifySms,
        data: {
          'phone': phone,
          'code': authCode,
          'action': 'login',
        },
      );
      return _consumeAuthResponse(
        res,
        fallbackKey: 'login_error_password_or_code',
      );
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  /// 用户密码登录
  Future<bool> loginCustomerWithPassword(
    String phone,
    String password, {
    String? captchaSessionId,
    String? captcha,
  }) async {
    lastLoginError = null;
    if (phone.isEmpty || password.isEmpty) {
      lastLoginError = _t('login_error_phone_or_password_required');
      return false;
    }

    try {
      final api = ApiService();
      final payload = <String, dynamic>{
        'phone': phone,
        'password': password,
        'type': 'customer',
      };
      if (captchaSessionId != null && captcha != null && captcha.isNotEmpty) {
        payload['captcha_session_id'] = captchaSessionId;
        payload['captcha'] = captcha.toUpperCase();
      }
      final res = await api.post(ApiConfig.authLogin, data: payload);
      return _consumeAuthResponse(
        res,
        fallbackKey: 'login_error_account_or_password',
      );
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  /// 用户注册并自动登录
  Future<bool> registerCustomer(
    String phone,
    String authCode,
    String password,
    String confirmPassword,
    bool acceptTerms, {
    String? captchaSessionId,
    String? captcha,
  }) async {
    lastLoginError = null;
    if (phone.isEmpty ||
        authCode.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      lastLoginError = _t('login_error_register_incomplete');
      return false;
    }
    if (!acceptTerms) {
      lastLoginError = _t('login_error_accept_agreement');
      return false;
    }

    try {
      final api = ApiService();
      final payload = <String, dynamic>{
        'phone': phone,
        'code': authCode,
        'password': password,
        'confirm_password': confirmPassword,
        'accept_terms': acceptTerms,
      };
      if (captchaSessionId != null && captcha != null && captcha.isNotEmpty) {
        payload['captcha_session_id'] = captchaSessionId;
        payload['captcha'] = captcha.toUpperCase();
      }
      final res = await api.post(ApiConfig.authRegister, data: payload);
      return _consumeAuthResponse(res, fallbackKey: 'login_register_failed');
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  /// 用户重置密码并自动登录
  Future<bool> resetCustomerPassword(
    String phone,
    String authCode,
    String password,
    String confirmPassword,
  ) async {
    lastLoginError = null;
    if (phone.isEmpty ||
        authCode.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      lastLoginError = _t('login_error_reset_incomplete');
      return false;
    }

    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authResetPassword,
        data: {
          'phone': phone,
          'code': authCode,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      return _consumeAuthResponse(res, fallbackKey: 'login_reset_failed');
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  Future<bool> changeCurrentUserPassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    lastLoginError = null;
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      lastLoginError = _t('login_error_password_info_incomplete');
      return false;
    }

    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.userChangePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      if (res.success) {
        return true;
      }
      lastLoginError =
          _localizeAuthMessage(res.message, 'profile_change_password_failed');
      return false;
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  Future<bool> deactivateCurrentAccount(String currentPassword) async {
    lastLoginError = null;
    if (currentPassword.isEmpty) {
      lastLoginError = _t('login_error_enter_password');
      return false;
    }

    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.userDeactivate,
        data: {
          'current_password': currentPassword,
        },
      );
      if (!res.success) {
        lastLoginError =
            _localizeAuthMessage(res.message, 'profile_deactivate_failed');
        return false;
      }

      await _clearSession(notifyServer: false);
      return true;
    } catch (e) {
      lastLoginError = _t('login_error_network');
      return false;
    }
  }

  Future<bool> loginCustomer(String phone, String authCode) {
    return loginCustomerWithSms(phone, authCode);
  }

  Future<void> _clearSession({required bool notifyServer}) async {
    final api = ApiService();
    if (notifyServer) {
      try {
        await api.post(ApiConfig.authLogout);
      } catch (_) {}
    }

    try {
      await ref.read(cartProvider.notifier).clearCart();
    } catch (e) {
      debugPrint('[Auth] 清空购物车失败: $e');
    }

    try {
      await api.clearAuth();
    } catch (_) {
      await _storage.clearUser();
    }

    lastLoginError = null;
    state = const AsyncValue.data(null);
  }

  /// 退出登录
  Future<void> logout() async {
    await _clearSession(notifyServer: true);
  }

  /// 登录后非阻塞地同步购物车到服务端
  void _syncCartAfterLogin() {
    try {
      ref.read(cartProvider.notifier).syncToServer();
    } catch (e) {
      debugPrint('[Auth] 购物车同步失败: $e');
    }
  }

  /// 发送短信验证码
  ///
  /// [phone] 手机号
  /// 返回值：{ success: bool, message: String }
  Future<Map<String, dynamic>> sendSmsCode(
    String phone, {
    String action = 'login',
  }) async {
    // 手机号格式校验
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      return {'success': false, 'message': '请输入正确的手机号'};
    }

    // 对接真实后端
    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authSendSms,
        data: {
          'phone': phone,
          'action': action,
        },
      );
      if (res.success) {
        return {'success': true, 'message': res.message ?? '验证码已发送，5分钟内有效'};
      }
      return {'success': false, 'message': res.message ?? '发送失败，请稍后重试'};
    } catch (e) {
      return {'success': false, 'message': '网络异常，请检查连接后重试'};
    }
  }

  /// 检查是否为管理员
  Future<Map<String, dynamic>> sendSmsCodeLocalized(
    String phone, {
    String action = 'login',
  }) async {
    final result = await sendSmsCode(phone, action: action);
    final success = result['success'] == true;
    final message = result['message']?.toString();
    if (success) {
      return {
        'success': true,
        'message': (message != null && message.trim().isNotEmpty)
            ? message
            : _t('login_sms_sent'),
      };
    }

    return {
      'success': false,
      'message': _localizeAuthMessage(message, 'login_error_send_failed'),
    };
  }

  bool get isAdmin {
    final user = state.valueOrNull;
    return user?.isAdmin ?? false;
  }

  /// 检查是否为超级管理员
  bool get isSuperAdmin {
    final user = state.valueOrNull;
    return user?.isSuperAdmin ?? false;
  }

  /// 获取当前用户
  UserModel? get currentUser => state.valueOrNull;

  /// 获取操作员编号
  int? get operatorNumber {
    final user = state.valueOrNull;
    return user?.operatorNumber;
  }

  /// 刷新登录状态
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // ========== 设备管理 ==========

  /// 获取登录设备列表
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final api = ApiService();
      final res = await api.get(ApiConfig.authDevices);
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final devices = data['devices'] as List?;
        return devices
                ?.map((d) => Map<String, dynamic>.from(d as Map))
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      debugPrint('[Auth] 获取设备列表失败: $e');
      return [];
    }
  }

  /// 移除指定设备
  Future<bool> removeDevice(String fingerprint) async {
    try {
      final api = ApiService();
      final res = await api.delete('${ApiConfig.authDevices}/$fingerprint');
      return res.success == true;
    } catch (e) {
      debugPrint('[Auth] 移除设备失败: $e');
      return false;
    }
  }

  /// 退出其他所有设备
  Future<Map<String, dynamic>> logoutOtherDevices() async {
    try {
      final api = ApiService();
      final res = await api.post('${ApiConfig.authDevices}/logout-others');
      if (res.success) {
        return {
          'success': true,
          'message': res.message ?? '已退出其他设备',
        };
      }
      return {
        'success': false,
        'message': res.message ?? '操作失败',
      };
    } catch (e) {
      return {'success': false, 'message': '网络异常，请检查连接后重试'};
    }
  }
}

// 简易版本的认证状态Provider（用于同步访问）
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

// 是否已登录Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// 是否为管理员Provider
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});

// 是否为操作员Provider
final isOperatorProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.userType == UserType.operator;
});

// 是否为普通用户Provider
final isCustomerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isCustomer ?? true;
});

// 当前用户角色Provider
final userRoleProvider = Provider<UserType>((ref) {
  return ref.watch(currentUserProvider)?.userType ?? UserType.customer;
});

// 操作员编号Provider
final operatorNumberProvider = Provider<int?>((ref) {
  return ref.watch(currentUserProvider)?.operatorNumber;
});
