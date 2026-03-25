library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import 'app_error_screen.dart';
import 'app_splash_screen.dart';
import 'privacy_consent_dialog.dart';

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  static const _privacyKey = 'privacy_accepted_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrivacy());
  }

  Future<void> _checkPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_privacyKey) ?? false;
    if (!accepted && mounted) {
      await _showPrivacyConsent();
    }
  }

  Future<void> _showPrivacyConsent() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrivacyConsentDialog(
        onAccept: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_privacyKey, true);
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
          }
        },
        onDecline: () => SystemNavigator.pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const AppSplashScreen(),
      error: (error, stack) => AppErrorScreen(error: error.toString()),
      data: (user) => user == null ? const LoginScreen() : const MainScreen(),
    );
  }
}
