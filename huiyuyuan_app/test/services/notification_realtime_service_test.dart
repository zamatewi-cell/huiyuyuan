import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/services/notification_realtime_service.dart';

void main() {
  group('NotificationRealtimeService', () {
    test('builds websocket uri from https base url', () {
      final uri = NotificationRealtimeService.buildNotificationWebSocketUri(
        baseUrl: 'https://xn--lsws2cdzg.top',
        token: 'abc123',
      );

      expect(uri.toString(), 'wss://xn--lsws2cdzg.top/ws/notifications?token=abc123');
    });

    test('ignores websocket handshake events', () {
      final connected =
          NotificationRealtimeService.parseRealtimeNotificationPayload({
        'type': 'connected',
        'message': '通知服务已连接',
        'message_key': 'ws_connected_message',
      });

      final subscribed =
          NotificationRealtimeService.parseRealtimeNotificationPayload({
        'type': 'subscribed',
        'message': '订阅已更新',
        'message_key': 'ws_subscribed_message',
      });

      expect(connected, isNull);
      expect(subscribed, isNull);
    });

    test('parses realtime order notifications into notification items', () {
      final item = NotificationRealtimeService.parseRealtimeNotificationPayload({
        'type': 'order_shipped',
        'order_id': 'ORD20260404001',
        'title': '订单已发货',
        'title_key': 'notification_order_shipped_title',
        'body': '您的订单已发货，顺丰 运单号 SF12345678',
        'body_key': 'notification_order_shipped_body_with_tracking',
        'body_args': {
          'carrier': '顺丰',
          'tracking': 'SF12345678',
        },
      });

      expect(item, isNotNull);
      expect(item!.id, 'ws:order_shipped:ORD20260404001');
      expect(item.type, NotificationType.order);
      expect(item.titleKey, 'notification_order_shipped_title');
      expect(item.bodyArgs?['tracking'], 'SF12345678');
      expect(item.isRead, isFalse);
    });
  });
}
