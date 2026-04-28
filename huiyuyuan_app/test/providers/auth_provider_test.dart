// 汇玉源 - 认证 Provider 测试
//
// 测试内容:
// - 管理员登录认证
// - 操作员登录认证
// - 登录状态管理
// - 权限检查
// - 退出登录
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/config/app_config.dart';
import 'package:huiyuyuan/config/local_debug_config.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/services/storage_service.dart';

const Map<String, dynamic> _debugCredentialConfig = {
  'ENABLE_LOCAL_CREDENTIAL_FALLBACK': true,
  'ADMIN_PHONE': '18925816362',
  'ADMIN_PASSWORD': 'admin123',
  'ADMIN_AUTH_CODE': '8888',
  'OPERATOR_PASSWORD': 'op123456',
};

void main() {
  // flutter_secure_storage 需要 ServicesBinding 初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late bool originalUseMockApi;

  setUp(() async {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;
    LocalDebugConfig.instance.replaceValuesForTesting(_debugCredentialConfig);
    // Mock flutter_secure_storage MethodChannel（单元测试环境无 platform 实现）
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final Map<String, String> secureStore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          if (value != null) secureStore[key] = value;
          return null;
        case 'read':
          return secureStore[call.arguments['key'] as String];
        case 'delete':
          secureStore.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'containsKey':
          return secureStore.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    });

    // 初始化 Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await StorageService().clearAll();
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    ApiConfig.useMockApi = originalUseMockApi;
    LocalDebugConfig.instance.clearForTesting();
  });

  group('管理员登录测试', () {
    test('未显式开启本地凭据兜底时应拒绝本地登录', () async {
      LocalDebugConfig.instance.replaceValuesForTesting(const {});

      expect(AppConfig.allowLocalCredentialFallback, isFalse);

      final authNotifier = container.read(authProvider.notifier);
      final result = await authNotifier.loginAdmin(
        '18925816362',
        'admin123',
        '8888',
      );

      expect(result, false);
      expect(container.read(currentUserProvider), isNull);
    });

    test('正确凭据应登录成功', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginAdmin(
        '18925816362', // 正确手机号
        'admin123', // 正确密码
        '8888', // 正确验证码
      );

      expect(result, true);

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.userType, UserType.admin);
      expect(user.isAdmin, true);
      expect(user.isSuperAdmin, true);
    });

    test('错误手机号应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginAdmin(
        '13800138000', // 错误手机号
        'admin123',
        '8888',
      );

      expect(result, false);
      expect(container.read(currentUserProvider), isNull);
    });

    test('错误密码应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginAdmin(
        '18925816362',
        'wrongpassword', // 错误密码
        '8888',
      );

      expect(result, false);
    });

    test('错误验证码应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginAdmin(
        '18925816362',
        'admin123',
        '1234', // 错误验证码
      );

      expect(result, false);
    });

    test('空凭据应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginAdmin('', '', '');

      expect(result, false);
    });
  });

  group('操作员登录测试', () {
    test('正确凭据应登录成功 - 数字格式', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator(
        '1', // 操作员编号
        'op123456', // 正确密码
      );

      expect(result, true);

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.userType, UserType.operator);
      expect(user.operatorNumber, 1);
      expect(user.isAdmin, false);
    });

    test('正确凭据应登录成功 - 操作员X格式', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator(
        '操作员5', // 中文格式
        'op123456',
      );

      expect(result, true);

      final user = container.read(currentUserProvider);
      expect(user!.operatorNumber, 5);
    });

    test('正确凭据应登录成功 - opX格式', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator(
        'op10',
        'op123456',
      );

      expect(result, true);

      final user = container.read(currentUserProvider);
      expect(user!.operatorNumber, 10);
    });

    test('操作员编号范围测试 - 1到10有效', () async {
      for (int i = 1; i <= 10; i++) {
        // 重新创建容器以清除状态
        container.dispose();
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer();

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.loginOperator('$i', 'op123456');

        expect(result, true, reason: '操作员 $i 应该能登录');
      }
    });

    test('操作员编号超出范围应失败 - 0', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator('0', 'op123456');

      expect(result, false);
    });

    test('操作员编号超出范围应失败 - 11', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator('11', 'op123456');

      expect(result, false);
    });

    test('操作员编号超出范围应失败 - 负数', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator('-1', 'op123456');

      expect(result, false);
    });

    test('错误密码应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator('1', 'wrongpass');

      expect(result, false);
    });

    test('无效用户名格式应登录失败', () async {
      final authNotifier = container.read(authProvider.notifier);

      final result = await authNotifier.loginOperator('abc', 'op123456');

      expect(result, false);
    });
  });

  group('登录状态 Provider 测试', () {
    test('未登录时 isLoggedInProvider 应为 false', () async {
      // 等待一下让 build 完成
      await Future.delayed(const Duration(milliseconds: 100));

      final isLoggedIn = container.read(isLoggedInProvider);
      expect(isLoggedIn, false);
    });

    test('登录后 isLoggedInProvider 应为 true', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('1', 'op123456');

      final isLoggedIn = container.read(isLoggedInProvider);
      expect(isLoggedIn, true);
    });

    test('未登录时 currentUserProvider 应为 null', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });

    test('管理员登录后 isAdminProvider 应为 true', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginAdmin('18925816362', 'admin123', '8888');

      final isAdmin = container.read(isAdminProvider);
      expect(isAdmin, true);
    });

    test('操作员登录后 isAdminProvider 应为 false', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('1', 'op123456');

      final isAdmin = container.read(isAdminProvider);
      expect(isAdmin, false);
    });

    test('操作员登录后 operatorNumberProvider 应返回编号', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('7', 'op123456');

      final operatorNumber = container.read(operatorNumberProvider);
      expect(operatorNumber, 7);
    });
  });

  group('退出登录测试', () {
    test('退出登录应清除用户状态', () async {
      final authNotifier = container.read(authProvider.notifier);

      // 先登录
      await authNotifier.loginOperator('1', 'op123456');
      expect(container.read(isLoggedInProvider), true);

      // 退出
      await authNotifier.logout();

      expect(container.read(isLoggedInProvider), false);
      expect(container.read(currentUserProvider), isNull);
    });

    test('退出登录后重新登录应正常', () async {
      final authNotifier = container.read(authProvider.notifier);

      // 登录 -> 退出 -> 重新登录
      await authNotifier.loginOperator('1', 'op123456');
      await authNotifier.logout();

      final result = await authNotifier.loginOperator('5', 'op123456');

      expect(result, true);
      expect(container.read(currentUserProvider)?.operatorNumber, 5);
    });
  });

  group('刷新状态测试', () {
    test('refresh 应重新加载登录状态', () async {
      final authNotifier = container.read(authProvider.notifier);

      await authNotifier.loginOperator('1', 'op123456');
      await authNotifier.refresh();

      // 刷新后状态应保持（因为数据已持久化）
      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
    });
  });

  group('权限属性测试', () {
    test('管理员应有 isAdmin 和 isSuperAdmin 权限', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginAdmin('18925816362', 'admin123', '8888');

      expect(authNotifier.isAdmin, true);
      expect(authNotifier.isSuperAdmin, true);
    });

    test('操作员不应有管理员权限', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('1', 'op123456');

      expect(authNotifier.isAdmin, false);
      expect(authNotifier.isSuperAdmin, false);
    });

    test('currentUser 应返回当前用户', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('3', 'op123456');

      final user = authNotifier.currentUser;
      expect(user, isNotNull);
      expect(user!.operatorNumber, 3);
    });

    test('operatorNumber 应返回操作员编号', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('8', 'op123456');

      expect(authNotifier.operatorNumber, 8);
    });
  });

  group('Token 生成测试', () {
    test('登录应生成唯一 Token', () async {
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.loginOperator('1', 'op123456');

      final user1 = authNotifier.currentUser;
      final token1 = user1?.token;

      // 退出重新登录
      await authNotifier.logout();

      // 重新创建容器
      container.dispose();
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      final newNotifier = container.read(authProvider.notifier);
      await newNotifier.loginOperator('1', 'op123456');

      final user2 = newNotifier.currentUser;
      final token2 = user2?.token;

      // Token 应该不同（包含时间戳）
      expect(token1, isNot(token2));
    });
  });
}
