import '../providers/app_settings_provider.dart';
import 'app_strings.dart';

class TranslatorGlobal {
  static final TranslatorGlobal _instance = TranslatorGlobal._internal();
  static TranslatorGlobal get instance => _instance;

  TranslatorGlobal._internal();

  static AppLanguage currentLang = AppLanguage.zhCN;

  static void updateLanguage(AppLanguage lang) {
    currentLang = lang;
  }

  String translate(String key, {Map<String, Object?> params = const {}}) {
    var value = AppStrings.get(currentLang, key);
    if (params.isEmpty) {
      return value;
    }

    params.forEach((paramKey, paramValue) {
      final replacement = paramValue?.toString() ?? '';
      value = value.replaceAll('{$paramKey}', replacement);
      value = value.replaceAll('\${$paramKey}', replacement);
    });
    return value;
  }
}
