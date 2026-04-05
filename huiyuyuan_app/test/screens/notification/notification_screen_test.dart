import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/screens/notification/notification_screen.dart';

import '../../support/notification_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpNotificationScreen(
    WidgetTester tester,
    StaticNotificationNotifier notifier,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: NotificationScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('NotificationScreen', () {
    testWidgets('marks a notification as read when opening details', (
      tester,
    ) async {
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'notification-1',
          title: '订单发货提醒',
          body: '您的订单已发货',
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
      ]);

      await pumpNotificationScreen(tester, notifier);

      expect(find.text('消息通知'), findsOneWidget);
      expect(find.text('全部已读'), findsOneWidget);

      await tester.tap(find.text('订单发货提醒'));
      await tester.pumpAndSettle();

      expect(notifier.state.single.isRead, isTrue);
      expect(find.text('您的订单已发货'), findsWidgets);
      expect(find.text('全部已读'), findsNothing);
    });

    testWidgets('marks all notifications as read from the action button', (
      tester,
    ) async {
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'notification-1',
          title: '订单发货提醒',
          body: '您的订单已发货',
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
        NotificationItem(
          id: 'notification-2',
          title: '活动通知',
          body: '和田玉新品已上架',
          type: NotificationType.promotion,
          time: DateTime(2026, 4, 4, 10, 1),
        ),
      ]);

      await pumpNotificationScreen(tester, notifier);

      expect(find.text('全部已读'), findsOneWidget);
      await markAllNotificationsAsRead(tester);

      expect(notifier.unreadCount, 0);
      expect(notifier.state.every((item) => item.isRead), isTrue);
      expect(find.text('全部已读'), findsNothing);
    });
  });
}
