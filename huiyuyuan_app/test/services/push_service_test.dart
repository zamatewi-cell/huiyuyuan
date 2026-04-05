import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';
import 'package:huiyuyuan/services/push_service.dart';

void main() {
  final originalLanguage = TranslatorGlobal.currentLang;

  tearDown(() {
    TranslatorGlobal.updateLanguage(originalLanguage);
  });

  group('PushNotification localization', () {
    test('uses key-based title and body when provided', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final notification = PushNotification(
        id: 'push-1',
        title: '测试通知',
        titleKey: 'push_test_title',
        body: '这是一条测试通知内容',
        bodyKey: 'push_test_body',
        type: NotificationType.system,
        receivedAt: DateTime(2026, 4, 4, 10),
      );

      expect(notification.localizedTitle, 'Test Notification');
      expect(
        notification.localizedBody,
        'This is a test notification message.',
      );
    });

    test('falls back to raw copy when localization keys are missing', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final notification = PushNotification(
        id: 'push-2',
        title: 'Fallback title',
        body: 'Fallback body',
        type: NotificationType.system,
        receivedAt: DateTime(2026, 4, 4, 10),
      );

      expect(notification.localizedTitle, 'Fallback title');
      expect(notification.localizedBody, 'Fallback body');
    });

    test('parses structured localization fields and created_at fallback', () {
      final notification = PushNotification.fromJson({
        'id': 'push-3',
        'title': '订单发货通知',
        'title_key': 'notification_demo_order_shipped_title',
        'title_args': {'tracking': 'SF10001'},
        'body': '您的订单已发货，请注意查收。',
        'body_key': 'notification_demo_order_shipped_body',
        'body_args': {'carrier': '顺丰'},
        'type': 'logistics',
        'created_at': '2026-04-04T10:00:00',
        'is_read': false,
      });

      expect(notification.receivedAt, DateTime.parse('2026-04-04T10:00:00'));
      expect(notification.titleKey, 'notification_demo_order_shipped_title');
      expect(notification.bodyKey, 'notification_demo_order_shipped_body');
      expect(notification.titleArgs?['tracking'], 'SF10001');
      expect(notification.bodyArgs?['carrier'], '顺丰');
    });

    test('parses wrapped notification payloads from the backend', () {
      final notifications = parsePushNotifications({
        'items': [
          {
            'id': 'push-4',
            'title': '订单发货通知',
            'title_key': 'notification_demo_order_shipped_title',
            'body': '您的订单已发货，请注意查收。',
            'body_key': 'notification_demo_order_shipped_body',
            'type': 'logistics',
            'created_at': '2026-04-04T10:00:00',
          },
        ],
        'total': 1,
        'unread': 1,
      });

      expect(notifications, hasLength(1));
      expect(notifications.first.id, 'push-4');
      expect(
        notifications.first.titleKey,
        'notification_demo_order_shipped_title',
      );
    });
  });
}
