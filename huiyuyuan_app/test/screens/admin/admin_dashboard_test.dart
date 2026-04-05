import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/screens/admin/admin_dashboard.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';

import '../../support/notification_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final adminUser = UserModel(
    id: 'admin-1',
    username: 'Admin 01',
    phone: '13800138009',
    userType: UserType.admin,
  );

  Future<void> pumpAdminDashboard(
    WidgetTester tester, {
    required NotificationNotifier notifier,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => adminUser),
          notificationProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: AdminDashboard(
            skipInitialLoad: true,
            pageOverrides: List<Widget>.generate(
              4,
              (index) => Center(child: Text('admin-page-$index')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Finder notificationBellTarget() {
    return find.ancestor(
      of: find.byIcon(Icons.notifications_none_rounded),
      matching: find.byType(GestureDetector),
    ).first;
  }

  group('AdminDashboard notifications', () {
    testWidgets('shows unread badge on header notification bell', (
      tester,
    ) async {
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'admin-notification-1',
          title: '系统通知',
          body: '管理员有 5 条未读消息',
          type: NotificationType.system,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
        NotificationItem(
          id: 'admin-notification-2',
          title: '订单提醒',
          body: '有新的支付确认待处理',
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 10, 1),
        ),
      ]);

      await pumpAdminDashboard(tester, notifier: notifier);

      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(notificationBadgeCount(tester), 2);
      expect(find.text('admin-page-0'), findsOneWidget);
    });

    testWidgets('opens notification center from header bell', (tester) async {
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'admin-notification-1',
          title: '系统通知',
          body: '管理员有未读消息',
          type: NotificationType.system,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
      ]);

      await pumpAdminDashboard(tester, notifier: notifier);

      await tester.tap(notificationBellTarget());
      await tester.pumpAndSettle();

      expect(find.text('消息通知'), findsOneWidget);
      expect(find.text('全部已读'), findsOneWidget);
      expect(find.text('系统通知'), findsWidgets);
    });

    testWidgets(
      'clears header badge after notification state changes in center',
      (tester) async {
        final notifier = StaticNotificationNotifier([
          NotificationItem(
            id: 'admin-notification-1',
            title: '系统通知',
            body: '管理员有未读消息',
            type: NotificationType.system,
            time: DateTime(2026, 4, 4, 10, 0),
          ),
          NotificationItem(
            id: 'admin-notification-2',
            title: '订单提醒',
            body: '有新的支付确认待处理',
            type: NotificationType.order,
            time: DateTime(2026, 4, 4, 10, 1),
          ),
        ]);

        await pumpAdminDashboard(tester, notifier: notifier);

        expect(notificationBadgeCount(tester), 2);

        await tester.tap(notificationBellTarget());
        await tester.pumpAndSettle();

        expect(find.text('消息通知'), findsOneWidget);
        await markAllNotificationsAsRead(tester);

        expect(notifier.unreadCount, 0);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        expect(notificationBadgeCount(tester), 0);
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      },
    );
  });
}
