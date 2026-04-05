import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../models/app_update_info.dart';
import 'api_service.dart';

class AppUpdateService {
  AppUpdateService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  static const skippedBuildKey = 'skipped_update_build_v1';

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

  Future<bool> openDownload(AppUpdateInfo info) async {
    if (!info.hasDownloadUrl) {
      return false;
    }

    final uri = Uri.tryParse(info.downloadUrl);
    if (uri == null) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
