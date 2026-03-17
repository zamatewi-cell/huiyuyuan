/// 汇玉源 - 多语言 Riverpod Provider
///
/// 功能:
/// - 提供当前语言对应的文本资源
/// - 通过 Riverpod 实现全局响应式更新
/// - 提供 BuildContext 扩展方便使用
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../l10n/app_strings.dart';

/// 当前语言文本集合 Provider
///
/// 用法:
/// ```dart
/// final strings = ref.watch(stringsProvider);
/// Text(strings['nav_home'] ?? '首页');
/// ```
final stringsProvider = Provider<Map<String, String>>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return AppStrings.of(language);
});

/// 多语言文本便捷获取 Provider
///
/// 用法:
/// ```dart
/// final t = ref.watch(tProvider);
/// Text(t('nav_home'));
/// ```
final tProvider = Provider<String Function(String)>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return (String key) => AppStrings.get(language, key);
});

/// BuildContext 扩展 - 在无法直接使用 ref 的地方使用
/// 注意：此扩展需要 ProviderScope 或 ConsumerWidget 中使用 ref
extension LocalizationExtension on WidgetRef {
  /// 获取翻译文本
  String tr(String key) {
    final language = watch(appSettingsProvider).language;
    return AppStrings.get(language, key);
  }
}
