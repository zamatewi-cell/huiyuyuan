library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_settings_provider.dart';
import '../themes/jewelry_theme.dart';
import '../l10n/translator_global.dart';
import 'app_router.dart';

class HuiYuYuanApp extends ConsumerStatefulWidget {
  const HuiYuYuanApp({super.key});

  @override
  ConsumerState<HuiYuYuanApp> createState() => _HuiYuYuanAppState();
}

class _HuiYuYuanAppState extends ConsumerState<HuiYuYuanApp> {
  ThemeMode _mapThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = _mapThemeMode(settings.themeMode);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? const Color(0xFF121218) : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ));
    });

    Locale appLocale;
    switch (settings.language) {
      case AppLanguage.zhCN:
        appLocale = const Locale('zh', 'CN');
        break;
      case AppLanguage.en:
        appLocale = const Locale('en', 'US');
        break;
      case AppLanguage.zhTW:
        appLocale = const Locale('zh', 'TW');
        break;
    }

    TranslatorGlobal.updateLanguage(settings.language);

    return MaterialApp(
      key: ValueKey(settings.language),
      title: AppStrings.get(settings.language, 'app_name'),
      debugShowCheckedModeBanner: false,
      theme: JewelryTheme.light,
      darkTheme: JewelryTheme.dark,
      themeMode: themeMode,
      locale: appLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('zh', 'TW'),
      ],
      home: const AppRouter(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
