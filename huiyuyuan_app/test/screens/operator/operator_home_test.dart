import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/providers/contact_provider.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/screens/operator/operator_home.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/notification_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final operatorUser = UserModel(
    id: 'operator-1',
    username: 'Operator 01',
    phone: '13800138000',
    userType: UserType.operator,
    isActive: true,
    operatorNumber: 1,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.useMockApi = true;
  });

  tearDown(() {
    ApiConfig.useMockApi = false;
  });

  Future<void> pumpOperatorHome(
    WidgetTester tester, {
    int unreadCount = 0,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => operatorUser),
          recentContactsLoaderProvider.overrideWith(
            (ref) => ({int limit = 5}) async => const [],
          ),
          notificationUnreadCountProvider.overrideWith((ref) => unreadCount),
        ],
        child: const MaterialApp(
          home: OperatorHome(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
  }

  group('OperatorHome notification reminders', () {
    testWidgets('shows unread badge on notification quick feature', (
      tester,
    ) async {
      await pumpOperatorHome(tester, unreadCount: 7);

      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('通知设置'), findsOneWidget);
    });

    testWidgets('shows unread summary in reminder settings sheet', (
      tester,
    ) async {
      await pumpOperatorHome(tester, unreadCount: 7);

      await tester.tap(find.text('通知设置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('提醒设置'), findsOneWidget);
      expect(find.text('当前有 7 条未读通知'), findsOneWidget);
      expect(find.text('消息通知'), findsOneWidget);
    });

    testWidgets(
      'full linkage: enter center → mark all read → return clears badge',
      (tester) async {
        final notifier = StaticNotificationNotifier([
          NotificationItem(
            id: 'op-notification-1',
            title: '订单待处理',
            body: '有新订单需要确认',
            type: NotificationType.order,
            time: DateTime(2026, 4, 5, 9, 0),
          ),
          NotificationItem(
            id: 'op-notification-2',
            title: '系统通知',
            body: '系统维护通知',
            type: NotificationType.system,
            time: DateTime(2026, 4, 5, 9, 30),
          ),
        ]);

        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => operatorUser),
              recentContactsLoaderProvider.overrideWith(
                (ref) => ({int limit = 5}) async => const [],
              ),
              notificationProvider.overrideWith((ref) => notifier),
            ],
            child: const MaterialApp(
              home: OperatorHome(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(seconds: 1));

        // Verify initial badge shows unread count
        expect(find.byType(NotificationBadgeIcon), findsOneWidget);
        expect(notificationBadgeCount(tester), 2);

        // Open reminder settings sheet
        await tester.tap(find.text('通知设置'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('提醒设置'), findsOneWidget);

        // Tap the "消息通知" button to go to notification center
        await tester.tap(find.text('消息通知'));
        await tester.pumpAndSettle();

        expect(find.text('消息通知'), findsOneWidget);
        expect(find.text('订单待处理'), findsWidgets);

        // Mark all as read
        await markAllNotificationsAsRead(tester);
        expect(notifier.unreadCount, 0);

        // Go back to operator home
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        // Badge should be cleared
        expect(notificationBadgeCount(tester), 0);
      },
    );
  });
}
