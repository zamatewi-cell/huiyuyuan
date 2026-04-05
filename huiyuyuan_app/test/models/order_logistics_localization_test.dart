import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/models/order_model.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

void main() {
  final originalLanguage = TranslatorGlobal.currentLang;

  tearDown(() {
    TranslatorGlobal.updateLanguage(originalLanguage);
  });

  group('LogisticsEntry localization', () {
    test('localizes shipped description in English', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final entry = LogisticsEntry.fromJson({
        'description': '商家已发货，顺丰速运 运单号 SF123456789',
        'time': '2026-04-04T10:00:00',
      });

      expect(
        entry.description,
        'Merchant shipped, 顺丰速运 Tracking No. SF123456789',
      );
    });

    test('localizes picked up description in English', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final entry = LogisticsEntry.fromJson({
        'description': '快件已被 顺丰速运 揽收',
        'time': '2026-04-04T10:00:00',
      });

      expect(entry.description, 'Picked up by 顺丰速运');
    });

    test('localizes paid description in English', () {
      TranslatorGlobal.updateLanguage(AppLanguage.en);

      final entry = LogisticsEntry.fromJson({
        'description': '订单已支付 ¥1999 (wechat)',
        'time': '2026-04-04T10:00:00',
      });

      expect(entry.description, 'Order paid ¥1999 (wechat)');
    });
  });
}
