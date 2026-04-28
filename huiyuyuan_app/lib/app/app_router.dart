library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/local_debug_config.dart';
import '../l10n/l10n_provider.dart';
import '../models/app_update_download_state.dart';
import '../providers/auth_provider.dart';
import '../screens/design/luxury_redesign_preview_screen.dart';
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

class _AppRouterState extends ConsumerState<AppRouter>
    with WidgetsBindingObserver {
  static const _privacyKey = 'privacy_accepted_v1';

  final AppUpdateService _appUpdateService = AppUpdateService();
  bool _startupChecksScheduled = false;
  bool _installPermissionHintShown = false;
  Timer? _updateMonitorTimer;
  StreamSubscription<AppUpdateDownloadState>? _updateStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStateSubscription = AppUpdateService.stateChanges.listen(
      _handleServiceUpdateState,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateMonitorTimer?.cancel();
    _updateStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumePendingUpdateFlow());
    }
  }

  Future<void> _runStartupChecks() async {
    await _checkPrivacy();
    if (kIsWeb) {
      return;
    }
    await _resumePendingUpdateFlow();
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
    if (kIsWeb || !mounted) {
      return;
    }

    final info = await _appUpdateService.fetchLatestUpdate();
    if (info == null || !mounted) {
      return;
    }

    final existingState =
        await _appUpdateService.getPendingAndroidUpdateState();
    if (existingState.buildNumber == info.latestBuildNumber &&
        (existingState.isActiveDownload ||
            existingState.canInstall ||
            existingState.requiresInstallPermission)) {
      if (existingState.isActiveDownload) {
        _ensureUpdateMonitorRunning();
      }
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
    final state = await _appUpdateService.startUpdate(info);
    if (!mounted) {
      return;
    }
    await _handleUpdateOutcome(state);
  }

  Future<void> _resumePendingUpdateFlow() async {
    if (kIsWeb || !mounted) {
      return;
    }

    final state = await _appUpdateService.getPendingAndroidUpdateState();
    if (!mounted) {
      return;
    }

    if (state.isActiveDownload) {
      _ensureUpdateMonitorRunning();
      return;
    }

    if (state.canInstall) {
      final installState =
          await _appUpdateService.resumePendingAndroidUpdateInstall();
      if (!mounted) {
        return;
      }
      await _handleUpdateOutcome(installState, showQueuedMessage: false);
      return;
    }

    if (state.requiresInstallPermission) {
      _showInstallPermissionHintOnce();
      return;
    }

    if (state.shouldShowFailure) {
      await _appUpdateService.clearPendingAndroidUpdateState();
      _showUpdateSnackBar(
        ref.tr('app_update_download_failed'),
        isError: true,
      );
      return;
    }

    if (state.status == AppUpdateDownloadStatus.idle) {
      _installPermissionHintShown = false;
    }
  }

  void _ensureUpdateMonitorRunning() {
    if (kIsWeb) {
      return;
    }
    _updateMonitorTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollPendingUpdateState()),
    );
  }

  Future<void> _pollPendingUpdateState() async {
    if (kIsWeb || !mounted) {
      _updateMonitorTimer?.cancel();
      _updateMonitorTimer = null;
      return;
    }

    final state = await _appUpdateService.getPendingAndroidUpdateState();
    if (!mounted) {
      return;
    }

    if (state.isActiveDownload) {
      return;
    }

    _updateMonitorTimer?.cancel();
    _updateMonitorTimer = null;

    if (state.canInstall) {
      final installState =
          await _appUpdateService.resumePendingAndroidUpdateInstall();
      if (!mounted) {
        return;
      }
      await _handleUpdateOutcome(installState, showQueuedMessage: false);
      return;
    }

    if (state.shouldShowFailure) {
      await _appUpdateService.clearPendingAndroidUpdateState();
      _showUpdateSnackBar(
        ref.tr('app_update_download_failed'),
        isError: true,
      );
    }
  }

  void _handleServiceUpdateState(AppUpdateDownloadState state) {
    if (kIsWeb || !mounted) {
      return;
    }

    if (state.isActiveDownload) {
      _ensureUpdateMonitorRunning();
      return;
    }

    if (state.canInstall) {
      unawaited(_resumePendingUpdateFlow());
    }
  }

  Future<void> _handleUpdateOutcome(
    AppUpdateDownloadState state, {
    bool showQueuedMessage = true,
  }) async {
    switch (state.status) {
      case AppUpdateDownloadStatus.external:
        return;
      case AppUpdateDownloadStatus.queued:
      case AppUpdateDownloadStatus.running:
      case AppUpdateDownloadStatus.paused:
        _ensureUpdateMonitorRunning();
        if (showQueuedMessage) {
          _showUpdateSnackBar(ref.tr('app_update_download_started'));
        }
        return;
      case AppUpdateDownloadStatus.installing:
        _installPermissionHintShown = false;
        _showUpdateSnackBar(ref.tr('app_update_install_started'));
        return;
      case AppUpdateDownloadStatus.permissionRequired:
        _showInstallPermissionHintOnce();
        return;
      case AppUpdateDownloadStatus.failed:
        _showUpdateSnackBar(
          ref.tr('app_update_download_failed'),
          isError: true,
        );
        return;
      case AppUpdateDownloadStatus.unavailable:
        _showUpdateSnackBar(
          ref.tr('app_update_link_unavailable'),
          isError: true,
        );
        return;
      case AppUpdateDownloadStatus.successful:
        await _resumePendingUpdateFlow();
        return;
      case AppUpdateDownloadStatus.idle:
        return;
    }
  }

  void _showInstallPermissionHintOnce() {
    if (_installPermissionHintShown) {
      return;
    }
    _installPermissionHintShown = true;
    _showUpdateSnackBar(ref.tr('app_update_install_permission_required'));
  }

  void _showUpdateSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
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
    final showUiRedesignPreview =
        LocalDebugConfig.instance.getBool('show_ui_redesign_preview') ?? false;

    if (showUiRedesignPreview) {
      return const LuxuryRedesignPreviewScreen();
    }

    if (!_startupChecksScheduled && authState.hasValue) {
      _startupChecksScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runStartupChecks());
      });
    }

    return authState.when(
      loading: () => const AppSplashScreen(),
      error: (error, stack) => AppErrorScreen(error: error.toString()),
      data: (user) => user == null ? const LoginScreen() : const MainScreen(),
    );
  }
}
