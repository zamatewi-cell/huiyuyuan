library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../services/app_update_service.dart';
import '../widgets/app_update_dialog.dart';
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
  final AppUpdateService _appUpdateService = AppUpdateService();
  bool _startupChecksScheduled = false;

  Future<void> _runStartupChecks() async {
    await _checkPrivacy();
    await _checkAppUpdate();
  }

  Future<void> _checkPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_privacyKey) ?? false;
    if (!accepted && mounted) {
      await _showPrivacyConsent();
    }
  }

  Future<void> _checkAppUpdate() async {
    if (!mounted) {
      return;
    }

    final info = await _appUpdateService.fetchLatestUpdate();
    if (info == null || !mounted) {
      return;
    }

    final shouldPrompt = await _appUpdateService.shouldPrompt(info);
    if (!shouldPrompt || !mounted) {
      return;
    }

    final action = await showDialog<AppUpdateAction>(
      context: context,
      barrierDismissible:
          !info.requiresImmediateUpdate(_appUpdateService.currentBuildNumber),
      builder: (ctx) => AppUpdateDialog(info: info),
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == AppUpdateAction.later) {
      await _appUpdateService.rememberSkippedBuild(info);
      return;
    }

    await _appUpdateService.clearSkippedBuild();
    final opened = await _appUpdateService.openDownload(info);
    if (!mounted || opened) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.tr('app_update_link_unavailable')),
      ),
    );
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

    if (!_startupChecksScheduled && authState.hasValue) {
      _startupChecksScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runStartupChecks();
      });
    }

    return authState.when(
      loading: () => const AppSplashScreen(),
      error: (error, stack) => AppErrorScreen(error: error.toString()),
      data: (user) => user == null ? const LoginScreen() : const MainScreen(),
    );
  }
}
