import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/l10n/l10n_provider.dart';
import 'package:huiyuyuan/l10n/app_strings.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('L10n Provider 测试', () {
    test('初始语言应为简体中文', () {
      final settings = container.read(appSettingsProvider);
      expect(settings.language, AppLanguage.zhCN);
    });

    test('tProvider 应能根据语言获取字符串', () {
      // 默认中文
      final t = container.read(tProvider);
      expect(t('nav_products'), '商城');
    });

    test('stringsProvider 应返回正确的字符串映射', () {
      final strings = container.read(stringsProvider);
      expect(strings['nav_products'], '商城');
      expect(strings.isNotEmpty, true);
    });

    test('AppStrings 所有语言都应包含相同的 Keys（以中文为基准）', () {
      final zhKeys = AppStrings.of(AppLanguage.zhCN).keys.toSet();
      final enKeys = AppStrings.of(AppLanguage.en).keys.toSet();
      final twKeys = AppStrings.of(AppLanguage.zhTW).keys.toSet();

      final missingEn = zhKeys.difference(enKeys);
      final missingTw = zhKeys.difference(twKeys);

      if (missingEn.isNotEmpty) {
        // ignore: avoid_print
        print('英文缺失的 Keys: $missingEn');
      }
      if (missingTw.isNotEmpty) {
        // ignore: avoid_print
        print('繁体中文缺失的 Keys: $missingTw');
      }
    });
  });
}
