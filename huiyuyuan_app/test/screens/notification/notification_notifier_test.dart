import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';

import '../../support/notification_test_helpers.dart';

void main() {
  group('NotificationNotifier', () {
    test('merges realtime notifications and avoids semantic duplicates', () async {
      final realtimeController = StreamController<NotificationItem>();
      final seededItem = NotificationItem(
        id: 'api-1',
        title: '订单已发货',
        titleKey: 'notification_order_shipped_title',
        body: '您的订单已发货，顺丰 运单号 SF12345678',
        bodyKey: 'notification_order_shipped_body_with_tracking',
        bodyArgs: const {
          'carrier': '顺丰',
          'tracking': 'SF12345678',
        },
        type: NotificationType.order,
        time: DateTime(2026, 4, 4, 10, 0),
      );
      final realtimeItem = NotificationItem(
        id: 'ws:order_shipped:ORD20260404001',
        title: '订单已发货',
        titleKey: 'notification_order_shipped_title',
        body: '您的订单已发货，顺丰 运单号 SF12345678',
        bodyKey: 'notification_order_shipped_body_with_tracking',
        bodyArgs: const {
          'carrier': '顺丰',
          'tracking': 'SF12345678',
        },
        type: NotificationType.order,
        time: DateTime(2026, 4, 4, 10, 1),
      );
      final secondRealtimeItem = NotificationItem(
        id: 'ws:payment_success:ORD20260404001',
        title: '支付已确认',
        titleKey: 'notification_payment_success_title',
        body: '订单 ORD20260404001 已确认到账',
        bodyKey: 'notification_payment_success_body',
        bodyArgs: const {'order_id': 'ORD20260404001'},
        type: NotificationType.order,
        time: DateTime(2026, 4, 4, 10, 2),
      );

      final notifier = NotificationNotifier.withDependencies(
        FakeNotificationRepository([seededItem]),
        realtimeNotifications: realtimeController.stream,
      );

      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, hasLength(1));

      realtimeController.add(realtimeItem);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.id, 'ws:order_shipped:ORD20260404001');

      realtimeController.add(secondRealtimeItem);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, hasLength(2));
      expect(notifier.state.first.id, 'ws:payment_success:ORD20260404001');

      await realtimeController.close();
      notifier.dispose();
    });

    test('unread count provider follows mark read transitions', () async {
      final seededItems = [
        NotificationItem(
          id: 'notification-1',
          title: '订单发货提醒',
          titleKey: 'notification_order_shipped_title',
          body: '您的订单已发货',
          bodyKey: 'notification_order_shipped_body',
          bodyArgs: const {'order_id': 'ORD20260404002'},
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
        NotificationItem(
          id: 'notification-2',
          title: '活动通知',
          body: '新品已上架',
          type: NotificationType.promotion,
          time: DateTime(2026, 4, 4, 10, 1),
        ),
      ];
      final notifier = NotificationNotifier.withDependencies(
        FakeNotificationRepository(seededItems),
      );
      final container = ProviderContainer(
        overrides: [
          notificationProvider.overrideWith((ref) => notifier),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationUnreadCountProvider), 2);

      container.read(notificationProvider.notifier).markAsRead('notification-1');
      expect(container.read(notificationUnreadCountProvider), 1);

      container.read(notificationProvider.notifier).markAllAsRead();
      expect(container.read(notificationUnreadCountProvider), 0);
    });
  });
}
