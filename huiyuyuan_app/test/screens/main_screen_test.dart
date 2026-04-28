import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/notification_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMainScreen(
    WidgetTester tester, {
    required UserModel user,
    int? unreadCount,
    NotificationNotifier? notifier,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => user),
          if (notifier != null)
            notificationProvider.overrideWith((ref) => notifier)
          else
            notificationUnreadCountProvider.overrideWith(
              (ref) => unreadCount ?? 0,
            ),
          mainScreenPageBuilderProvider.overrideWith(
            (ref) => (role) => List<Widget>.generate(
                  5,
                  (index) => Center(child: Text('page-$index-${role.name}')),
                ),
          ),
        ],
        child: const MaterialApp(
          home: MainScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  group('MainScreen notification badge', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('customer role shows order tab and unread badge on profile', (
      tester,
    ) async {
      final customer = UserModel(
        id: 'customer-1',
        username: 'Customer 01',
        phone: '13800138001',
        userType: UserType.customer,
      );

      await pumpMainScreen(
        tester,
        user: customer,
        unreadCount: 3,
      );

      expect(find.text('商城'), findsOneWidget);
      expect(find.text('我的订单'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('page-0-customer'), findsOneWidget);
    });

    testWidgets('operator role reuses unread badge provider on profile tab', (
      tester,
    ) async {
      final operator = UserModel(
        id: 'operator-1',
        username: 'Operator 01',
        phone: '13800138002',
        userType: UserType.operator,
        operatorNumber: 1,
      );

      await pumpMainScreen(
        tester,
        user: operator,
        unreadCount: 8,
      );

      expect(find.text('工作台'), findsOneWidget);
      expect(find.text('商城'), findsWidgets);
      expect(find.text('我的'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('page-0-operator'), findsOneWidget);
    });

    testWidgets('operator without AI and radar permissions stays on workbench',
        (
      tester,
    ) async {
      final operator = UserModel(
        id: 'operator-locked',
        username: 'Operator Locked',
        phone: '13800138021',
        userType: UserType.operator,
        operatorNumber: 2,
        permissions: const ['orders'],
      );

      await pumpMainScreen(
        tester,
        user: operator,
        unreadCount: 1,
      );

      await tester.tap(find.text('AI助手'));
      await tester.pumpAndSettle();

      expect(find.text('page-0-operator'), findsOneWidget);
      expect(find.text('当前操作员没有此功能权限，请联系管理员开通。'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    });

    testWidgets('operator with permissions can open AI page', (tester) async {
      final operator = UserModel(
        id: 'operator-open',
        username: 'Operator Open',
        phone: '13800138022',
        userType: UserType.operator,
        operatorNumber: 3,
        permissions: const ['shop_radar', 'ai_assistant'],
      );

      await pumpMainScreen(
        tester,
        user: operator,
        unreadCount: 0,
      );

      await tester.tap(find.text('AI助手'));
      await tester.pumpAndSettle();

      expect(find.text('page-3-operator'), findsOneWidget);
    });

    testWidgets('admin role reuses unread badge provider on profile tab', (
      tester,
    ) async {
      final admin = UserModel(
        id: 'admin-1',
        username: 'Admin 01',
        phone: '13800138003',
        userType: UserType.admin,
      );

      await pumpMainScreen(
        tester,
        user: admin,
        unreadCount: 12,
      );

      expect(find.text('仪表盘'), findsOneWidget);
      expect(find.text('商城'), findsWidgets);
      expect(find.text('我的'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('page-0-admin'), findsOneWidget);
    });

    testWidgets('profile badge reacts to shared notification notifier updates',
        (
      tester,
    ) async {
      final customer = UserModel(
        id: 'customer-2',
        username: 'Customer 02',
        phone: '13800138011',
        userType: UserType.customer,
      );
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'notification-1',
          title: '系统通知',
          body: '您有新的系统消息',
          type: NotificationType.system,
          time: DateTime(2026, 4, 4, 11, 0),
        ),
        NotificationItem(
          id: 'notification-2',
          title: '订单提醒',
          body: '您的订单已更新',
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 11, 1),
        ),
      ]);

      await pumpMainScreen(
        tester,
        user: customer,
        notifier: notifier,
      );

      expect(find.text('2'), findsOneWidget);

      notifier.markAllAsRead();
      await tester.pumpAndSettle();

      expect(notifier.unreadCount, 0);
      expect(find.text('2'), findsNothing);
    });
  });
}
