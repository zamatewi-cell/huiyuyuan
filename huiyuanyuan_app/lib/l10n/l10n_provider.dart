library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_settings_provider.dart';
import '../utils/text_sanitizer.dart';

final stringsProvider = Provider<Map<String, String>>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return AppStrings.of(language);
});

final tProvider = Provider<String Function(String)>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return (String key) => sanitizeUtf16(AppStrings.get(language, key));
});

extension LocalizationExtension on WidgetRef {
  String tr(String key) {
    final language = watch(appSettingsProvider).language;
    return sanitizeUtf16(AppStrings.get(language, key));
  }
}
