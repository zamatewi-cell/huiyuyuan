/// 汇玉源 - 认证状态管理
///
/// 功能:
/// - 管理员登录认证
/// - 操作员登录认证
/// - 登录状态持久化
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_config.dart';

/// 认证状态Provider
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

/// 认证状态Notifier
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
  /// [phone] 手机号 (固定为 18937766669)
  /// [password] 密码
  /// [authCode] 管理员验证码
  Future<bool> loginAdmin(
      String phone, String password, String authCode) async {
    // 验证固定管理员账号
    if (phone != AppConfig.adminPhone) {
      return false;
    }

    // 尝试后端 API 认证
    if (!ApiConfig.useMockApi) {
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
          final data = (rawData is Map<String, dynamic>)
              ? rawData
              : <String, dynamic>{};
          final token = (data['token'] ?? '').toString();
          final userRaw = data['user'];
          final userData = (userRaw is Map<String, dynamic>)
              ? Map<String, dynamic>.from(userRaw)
              : <String, dynamic>{};
          userData['token'] = token;

          try { await _storage.saveToken(token); } catch (_) {}
          try { await api.setToken(token); } catch (_) {}

          final user = UserModel.fromJson(userData);
          await _storage.saveUser(user.toJson());
          state = AsyncValue.data(user);
          return true;
        }
        // API 返回错误时 fall through 到本地离线验证
      } catch (_) {
        // API 不可用时 fallback 到本地验证（仅 Debug 构建有效）
      }
    }

    // ========== Mock / 离线 fallback ==========
    // Release 构建中 AppConfig 凭据为空字符串，此分支不会通过
    final expectedPwd = AppConfig.adminPassword;
    final expectedCode = AppConfig.adminAuthCode;
    if (expectedPwd.isEmpty || expectedCode.isEmpty) return false;
    if (password != expectedPwd || authCode != expectedCode) return false;

    try {
      final user = UserModel(
        id: 'admin_001',
        username: '超级管理员',
        phone: phone,
        userType: UserType.admin,
        isActive: true,
        token: 'admin_token_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime.now(),
      );

      // 保存到本地
      await _storage.saveUser(user.toJson());

      // 更新状态
      state = AsyncValue.data(user);

      return true;
    } catch (e) {
      return false;
    }
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
    if (!ApiConfig.useMockApi) {
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
          final data = (rawData is Map<String, dynamic>)
              ? rawData
              : <String, dynamic>{};
          final token = (data['token'] ?? '').toString();
          final userRaw = data['user'];
          final userData = (userRaw is Map<String, dynamic>)
              ? Map<String, dynamic>.from(userRaw)
              : <String, dynamic>{};
          userData['token'] = token;

          try { await _storage.saveToken(token); } catch (_) {}
          try { await api.setToken(token); } catch (_) {}

          final user = UserModel.fromJson(userData);
          await _storage.saveUser(user.toJson());
          state = AsyncValue.data(user);
          return true;
        }
        // API 返回错误时 fall through 到本地离线验证
      } catch (_) {
        // API 不可用时 fallback 到本地验证（仅 Debug 构建有效）
      }
    }

    // ========== Mock / 离线 fallback ==========
    final expectedPwd = AppConfig.operatorDefaultPassword;
    if (expectedPwd.isEmpty) return false;
    if (password != expectedPwd) return false;

    try {
      final operatorId = 'operator_$operatorNumber';

      final user = UserModel(
        id: operatorId,
        username: '操作员$operatorNumber号',
        userType: UserType.operator,
        isActive: true,
        token:
            'op_token_${operatorNumber}_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime.now(),
        operatorNumber: operatorNumber,
      );

      // 保存到本地
      await _storage.saveUser(user.toJson());
      await _storage.saveOperatorId(operatorId);

      // 更新状态
      state = AsyncValue.data(user);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 用户登录
  ///
  /// [phone] 手机号
  /// [authCode] 验证码
  /// 登录结果错误信息（用于 UI 展示）
  String? lastLoginError;

  Future<bool> loginCustomer(String phone, String authCode) async {
    lastLoginError = null;
    if (phone.isEmpty || authCode.isEmpty) {
      lastLoginError = '手机号或验证码不能为空';
      return false;
    }

    if (!ApiConfig.useMockApi) {
      // 对接真实 FastAPI 后端（/api/auth/verify-sms）
      try {
        final api = ApiService();
        final res = await api.post(
          ApiConfig.authVerifySms,
          data: {
            'phone': phone,
            'code': authCode,
          },
        );

        if (res.success && res.data != null) {
          // 安全解析响应数据，避免任何 null-check 异常
          final rawData = res.data;
          final data = (rawData is Map<String, dynamic>)
              ? rawData
              : <String, dynamic>{};

          final token = (data['token'] ?? '').toString();
          final refreshToken = (data['refresh_token'] ?? '').toString();
          final userRaw = data['user'];
          final userData = (userRaw is Map<String, dynamic>)
              ? Map<String, dynamic>.from(userRaw)
              : <String, dynamic>{};
          userData['token'] = token;

          // 安全存储 Token（已内置 try-catch + SharedPreferences 回退）
          try { await _storage.saveToken(token); } catch (_) {}
          try {
            if (refreshToken.isNotEmpty) {
              await _storage.saveRefreshToken(refreshToken);
            }
          } catch (_) {}
          try { await api.setToken(token); } catch (_) {}

          final user = UserModel.fromJson(userData);
          await _storage.saveUser(user.toJson());
          state = AsyncValue.data(user);
          return true;
        }
        lastLoginError = res.message ?? '验证失败，请重试';
        return false;
      } catch (e) {
        lastLoginError = '网络异常：$e';
        return false;
      }
    }

    // ========== 以下为 Mock 模式 ==========

    // 测试环境: 万能验证码 8888 或等于手机号后4位
    if (authCode != '8888' &&
        authCode != phone.substring(phone.length > 4 ? phone.length - 4 : 0)) {
      return false;
    }

    try {
      final user = UserModel(
        id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
        username:
            '用户_${phone.substring(phone.length > 4 ? phone.length - 4 : 0)}',
        phone: phone,
        userType: UserType.customer,
        isActive: true,
        token: 'customer_token_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 保存到本地
      await _storage.saveUser(user.toJson());

      // 更新状态
      state = AsyncValue.data(user);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _storage.clearUser(); // 同时清除加密 Token
    state = const AsyncValue.data(null);
  }

  /// 发送短信验证码
  ///
  /// [phone] 手机号（正式后端部署后生效，Mock 模式下直接返回 true）
  /// 返回值：{ success: bool, message: String }
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    // 手机号格式校验
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      return {'success': false, 'message': '请输入正确的手机号'};
    }

    // Mock 模式：直接提示万能验证码，不真实发送
    if (ApiConfig.useMockApi) {
      return {'success': true, 'message': '（测试模式）万能验证码: 8888'};
    }

    // 对接真实后端
    try {
      final api = ApiService();
      final res = await api.post(
        ApiConfig.authSendSms,
        data: {'phone': phone},
      );
      if (res.success) {
        // 测试模式下后端 message 里包含验证码，直接透传给 UI 显示
        return {'success': true, 'message': res.message ?? '验证码已发送，5分钟内有效'};
      }
      return {'success': false, 'message': res.message ?? '发送失败，请稍后重试'};
    } catch (e) {
      return {'success': false, 'message': '网络异常，请检查连接后重试'};
    }
  }

  /// 检查是否为管理员
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
}

/// 简易版本的认证状态Provider（用于同步访问）
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

/// 是否已登录Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// 是否为管理员Provider
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});

/// \u662F\u5426\u4E3A\u64CD\u4F5C\u5458Provider
final isOperatorProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.userType == UserType.operator;
});

/// \u662F\u5426\u4E3A\u666E\u901A\u7528\u6237Provider
final isCustomerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isCustomer ?? true;
});

/// \u5F53\u524D\u7528\u6237\u89D2\u8272Provider
final userRoleProvider = Provider<UserType>((ref) {
  return ref.watch(currentUserProvider)?.userType ?? UserType.customer;
});

/// 操作员编号Provider
final operatorNumberProvider = Provider<int?>((ref) {
  return ref.watch(currentUserProvider)?.operatorNumber;
});
