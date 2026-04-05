library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_settings_provider.dart';
import '../utils/text_sanitizer.dart';

final stringsProvider = Provider<Map<String, String>>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return AppStrings.of(language);
});

final tProvider =
    Provider<String Function(String, {Map<String, Object?> params})>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return (String key, {Map<String, Object?> params = const {}}) =>
      sanitizeUtf16(AppStrings.get(language, key, params: params));
});

extension LocalizationExtension on WidgetRef {
  String tr(String key, {Map<String, Object?> params = const {}}) {
    final language = watch(appSettingsProvider).language;
    return sanitizeUtf16(AppStrings.get(language, key, params: params));
  }
}
