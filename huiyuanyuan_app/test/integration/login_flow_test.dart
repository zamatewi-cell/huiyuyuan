/// 汇玉源 - 登录流程集成测试
/// 
/// 测试场景:
/// 1. 管理员完整登录流程
/// 2. 操作员完整登录流程
/// 3. 登录状态管理
/// 4. Provider 状态测试
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:huiyuanyuan/main.dart';
import 'package:huiyuanyuan/screens/login_screen.dart';

import 'package:huiyuanyuan/providers/auth_provider.dart';
import 'package:huiyuanyuan/models/user_model.dart';
import 'package:huiyuanyuan/config/api_config.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // mock flutter_secure_storage
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final Map<String, String> _store = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          if (value != null) _store[key] = value;
          return null;
        case 'read':
          return _store[call.arguments['key'] as String];
        case 'delete':
          _store.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          _store.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(_store);
        case 'containsKey':
          return _store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    });
  });

  group('登录页面 UI 测试', () {
    testWidgets('登录页面应正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 用 pump + Duration 代替 pumpAndSettle（避免动画永不结束导致超时）
      await tester.pump(const Duration(seconds: 1));

      // 验证登录页面存在
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('应显示 MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('AuthProvider 登录测试', () {
    test('正确的管理员凭据应登录成功', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);
      
      final result = await authNotifier.loginAdmin(
        '18937766669',
        'admin123',
        '8888',
      );
      
      expect(result, true);
      
      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.userType, UserType.admin);
      expect(user.isAdmin, true);
    });

    test('错误的管理员手机号应登录失败', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);
      
      final result = await authNotifier.loginAdmin(
        '13800138000',
        'admin123',
        '8888',
      );
      
      expect(result, false);
    });

    test('正确的操作员凭据应登录成功', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);
      
      final result = await authNotifier.loginOperator('1', 'op123456');
      
      expect(result, true);
      
      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.userType, UserType.operator);
      expect(user.operatorNumber, 1);
    });

    test('操作员编号范围 1-10 应有效', () async {
      for (int i = 1; i <= 10; i++) {
        final container = ProviderContainer();
        
        final result = await container.read(authProvider.notifier).loginOperator('$i', 'op123456');
        expect(result, true, reason: '操作员 $i 应该能登录');
        
        container.dispose();
        SharedPreferences.setMockInitialValues({});
      }
    });

    test('操作员编号 0 应无效', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(authProvider.notifier).loginOperator('0', 'op123456');
      expect(result, false);
    });

    test('操作员编号 11 应无效', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(authProvider.notifier).loginOperator('11', 'op123456');
      expect(result, false);
    });
  });

  group('退出登录测试', () {
    test('退出登录应清除用户状态', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);
      
      // 登录 -> 退出 -> 重新登录
      await authNotifier.loginOperator('1', 'op123456');
      await authNotifier.logout();
      
      final result = await authNotifier.loginOperator('5', 'op123456');
      
      expect(result, true);
      expect(container.read(currentUserProvider)?.operatorNumber, 5);
    });
  });

  group('应用启动测试', () {
    testWidgets('应用应正确启动', (WidgetTester tester) async {
      // 启用 Mock 模式，避免 Dio HTTP 请求在 fakeAsync 中产生未完成定时器
      // （HuiYuYuanApp 启动时 OrderNotifier、ContactService 等会发起 API 请求）
      final originalUseMock = ApiConfig.useMockApi;
      ApiConfig.useMockApi = true;
      addTearDown(() => ApiConfig.useMockApi = originalUseMock);

      await tester.pumpWidget(
        const ProviderScope(
          child: HuiYuYuanApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // 验证应用启动
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('登录状态 Provider 测试', () {
    test('isLoggedInProvider 初始应为 false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 等待初始化
      await Future.delayed(const Duration(milliseconds: 100));
      
      final isLoggedIn = container.read(isLoggedInProvider);
      expect(isLoggedIn, false);
    });

    test('登录后 isLoggedInProvider 应为 true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).loginOperator('1', 'op123456');
      
      expect(container.read(isLoggedInProvider), true);
    });

    test('管理员登录后 isAdminProvider 应为 true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).loginAdmin('18937766669', 'admin123', '8888');
      
      expect(container.read(isAdminProvider), true);
    });

    test('操作员登录后 isAdminProvider 应为 false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).loginOperator('1', 'op123456');
      
      expect(container.read(isAdminProvider), false);
    });

    test('operatorNumberProvider 应返回正确编号', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).loginOperator('7', 'op123456');
      
      expect(container.read(operatorNumberProvider), 7);
    });
  });

  group('AuthNotifier 属性测试', () {
    test('isAdmin 应正确返回', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      
      await notifier.loginAdmin('18937766669', 'admin123', '8888');
      expect(notifier.isAdmin, true);
    });

    test('isSuperAdmin 应正确返回', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      
      await notifier.loginAdmin('18937766669', 'admin123', '8888');
      expect(notifier.isSuperAdmin, true);
    });

    test('currentUser 应返回当前用户', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      
      await notifier.loginOperator('3', 'op123456');
      
      final user = notifier.currentUser;
      expect(user, isNotNull);
      expect(user!.operatorNumber, 3);
    });

    test('operatorNumber 应返回操作员编号', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      
      await notifier.loginOperator('8', 'op123456');
      expect(notifier.operatorNumber, 8);
    });
  });
}
