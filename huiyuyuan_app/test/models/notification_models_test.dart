import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

void main() {
  final originalLanguage = TranslatorGlobal.currentLang;

  tearDown(() {
    TranslatorGlobal.updateLanguage(originalLanguage);
  });

  group('NotificationItem localization', () {
    test('uses key-based title and body when provided', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final item = NotificationItem(
        id: 'n1',
        title: '订单发货通知',
        titleKey: 'notification_demo_order_shipped_title',
        body: '您的订单已发货，请注意查收。',
        bodyKey: 'notification_demo_order_shipped_body',
        type: NotificationType.order,
        time: DateTime(2026, 4, 4, 10),
      );

      expect(item.localizedTitle, 'Order shipped');
      expect(
        item.localizedBody,
        'Your order has been shipped. Please watch for delivery.',
      );
    });

    test('falls back to raw title and body when keys are missing', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final item = NotificationItem(
        id: 'n2',
        title: 'Fallback title',
        body: 'Fallback body',
        type: NotificationType.system,
        time: DateTime(2026, 4, 4, 10),
      );

      expect(item.localizedTitle, 'Fallback title');
      expect(item.localizedBody, 'Fallback body');
    });

    test('parses created_at and structured localization fields from json', () {
      final item = NotificationItem.fromJson({
        'id': 'n3',
        'title': '订单发货通知',
        'title_key': 'notification_demo_order_shipped_title',
        'body': '您的订单已发货，请注意查收。',
        'body_key': 'notification_demo_order_shipped_body',
        'type': 'order',
        'created_at': '2026-04-04T10:00:00',
        'is_read': false,
      });

      expect(item.time, DateTime.parse('2026-04-04T10:00:00'));
      expect(item.titleKey, 'notification_demo_order_shipped_title');
      expect(item.bodyKey, 'notification_demo_order_shipped_body');
    });
  });
}
