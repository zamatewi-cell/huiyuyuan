import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../models/app_update_download_state.dart';
import '../models/app_update_info.dart';
import 'api_service.dart';

class AppUpdateService {
  AppUpdateService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  static const skippedBuildKey = 'skipped_update_build_v1';
  static const MethodChannel _channel = MethodChannel(
    'com.huiyuyuan.app/app_update',
  );
  static final StreamController<AppUpdateDownloadState> _stateController =
      StreamController<AppUpdateDownloadState>.broadcast();

  static Stream<AppUpdateDownloadState> get stateChanges =>
      _stateController.stream;

  final ApiService _apiService;

  String get currentPlatform {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
      default:
        return 'android';
    }
  }

  bool get supportsManagedAndroidUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  int get currentBuildNumber => AppConfig.appBuildNumber;

  Future<AppUpdateInfo?> fetchLatestUpdate() async {
    final result = await _apiService.get<Map<String, dynamic>>(
      ApiConfig.appVersionInfo,
      params: {'platform': currentPlatform},
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json;
        }
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      },
    );

    if (!result.success || result.data == null) {
      return null;
    }

    return AppUpdateInfo.fromJson(result.data!);
  }

  Future<bool> shouldPrompt(AppUpdateInfo info) async {
    if (kIsWeb) {
      return false;
    }

    if (!info.hasNewerBuildThan(currentBuildNumber)) {
      return false;
    }

    if (info.requiresImmediateUpdate(currentBuildNumber)) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final skippedBuild = prefs.getInt(skippedBuildKey) ?? 0;
    return skippedBuild != info.latestBuildNumber;
  }

  Future<void> rememberSkippedBuild(AppUpdateInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(skippedBuildKey, info.latestBuildNumber);
  }

  Future<void> clearSkippedBuild() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(skippedBuildKey);
  }

  Future<AppUpdateDownloadState> startUpdate(AppUpdateInfo info) async {
    if (!info.hasDownloadUrl) {
      return const AppUpdateDownloadState(
        status: AppUpdateDownloadStatus.unavailable,
      );
    }

    if (supportsManagedAndroidUpdate) {
      try {
        final downloadUrls = info.downloadUrls
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        final state = await _invokeNativeState(
          'enqueueUpdateDownload',
          {
            'url': info.downloadUrl,
            'urls': downloadUrls,
            'version': info.latestVersion,
            'buildNumber': info.latestBuildNumber,
            'fileName': 'huiyuyuan-update-${info.latestBuildNumber}.apk',
            'title': 'HuiYuYuan Update',
            'description': 'Downloading version ${info.latestVersion}',
            'mimeType': info.downloadContentType.isNotEmpty
                ? info.downloadContentType
                : 'application/vnd.android.package-archive',
            'sha256': info.downloadSha256,
            'expectedSizeBytes': info.downloadSizeBytes,
          },
        );
        _emitState(state);
        return state;
      } on PlatformException {
        // Fall back to the external browser if the native bridge is unavailable.
      }
    }

    final uri = Uri.tryParse(info.downloadUrl);
    if (uri == null) {
      return const AppUpdateDownloadState(
        status: AppUpdateDownloadStatus.failed,
      );
    }

    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    final state = AppUpdateDownloadState(
      status: opened
          ? AppUpdateDownloadStatus.external
          : AppUpdateDownloadStatus.failed,
    );
    _emitState(state);
    return state;
  }

  Future<AppUpdateDownloadState> getPendingAndroidUpdateState() async {
    if (!supportsManagedAndroidUpdate) {
      return const AppUpdateDownloadState(status: AppUpdateDownloadStatus.idle);
    }

    return _invokeNativeState(
      'getUpdateDownloadState',
      {'currentBuildNumber': currentBuildNumber},
    );
  }

  Future<AppUpdateDownloadState> resumePendingAndroidUpdateInstall() async {
    if (!supportsManagedAndroidUpdate) {
      return const AppUpdateDownloadState(status: AppUpdateDownloadStatus.idle);
    }

    final state = await _invokeNativeState(
      'resumeDownloadedUpdateInstall',
      {'currentBuildNumber': currentBuildNumber},
    );
    _emitState(state);
    return state;
  }

  Future<void> clearPendingAndroidUpdateState() async {
    if (!supportsManagedAndroidUpdate) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'clearUpdateDownloadState',
        {'currentBuildNumber': currentBuildNumber},
      );
    } on PlatformException {
      // Ignore local cleanup failures; stale state is harmless.
    }
  }

  Future<AppUpdateDownloadState> _invokeNativeState(
    String method, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      method,
      arguments,
    );
    return AppUpdateDownloadState.fromJson(result);
  }

  void _emitState(AppUpdateDownloadState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
