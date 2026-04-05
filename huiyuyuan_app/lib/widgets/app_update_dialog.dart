import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/app_update_info.dart';

enum AppUpdateAction {
  updateNow,
  later,
}

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.info,
  });

  final AppUpdateInfo info;

  bool get _forceUpdate =>
      info.requiresImmediateUpdate(AppConfig.appBuildNumber);

  @override
  Widget build(BuildContext context) {
    final copy = _UpdateCopy.fromContext(context, forceUpdate: _forceUpdate);

    return WillPopScope(
      onWillPop: () async => !_forceUpdate,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                copy.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _VersionCard(
                  label: copy.versionLabel,
                  value: '${info.latestVersion} (${info.latestBuildNumber})',
                ),
                const SizedBox(height: 10),
                _VersionCard(
                  label: copy.currentVersionLabel,
                  value:
                      '${AppConfig.appVersion} (${AppConfig.appBuildNumber})',
                ),
                if (info.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    copy.notesLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final note in info.releaseNotes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Icon(Icons.circle, size: 6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (!info.hasDownloadUrl) ...[
                  const SizedBox(height: 12),
                  Text(
                    copy.noLinkHint,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!_forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(AppUpdateAction.later),
              child: Text(copy.laterLabel),
            ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(AppUpdateAction.updateNow),
            icon: const Icon(Icons.download_rounded),
            label: Text(copy.updateLabel),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _UpdateCopy {
  const _UpdateCopy({
    required this.title,
    required this.subtitle,
    required this.versionLabel,
    required this.currentVersionLabel,
    required this.notesLabel,
    required this.laterLabel,
    required this.updateLabel,
    required this.noLinkHint,
  });

  final String title;
  final String subtitle;
  final String versionLabel;
  final String currentVersionLabel;
  final String notesLabel;
  final String laterLabel;
  final String updateLabel;
  final String noLinkHint;

  factory _UpdateCopy.fromContext(
    BuildContext context, {
    required bool forceUpdate,
  }) {
    final locale = Localizations.localeOf(context);
    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toUpperCase();
    final isTraditional = locale.languageCode == 'zh' &&
        (country == 'TW' ||
            country == 'HK' ||
            country == 'MO' ||
            script == 'HANT');

    if (locale.languageCode == 'en') {
      return _UpdateCopy(
        title: forceUpdate ? 'Update required' : 'New version available',
        subtitle: forceUpdate
            ? 'This version is no longer supported. Please update before continuing.'
            : 'A newer version is ready. You can update now or keep your current version for the moment.',
        versionLabel: 'Latest version',
        currentVersionLabel: 'Current version',
        notesLabel: 'What is new',
        laterLabel: 'Later',
        updateLabel: 'Update now',
        noLinkHint:
            'The download link is not ready yet. Please contact support.',
      );
    }

    if (isTraditional) {
      return _UpdateCopy(
        title: forceUpdate ? '需要更新' : '發現新版本',
        subtitle: forceUpdate
            ? '目前版本已停止支援，請先更新後再繼續使用。'
            : '伺服器已提供較新版本，你可以現在更新，或稍後再處理。',
        versionLabel: '最新版本',
        currentVersionLabel: '目前版本',
        notesLabel: '更新內容',
        laterLabel: '稍後',
        updateLabel: '立即更新',
        noLinkHint: '目前尚未提供下載連結，請聯絡管理員協助。',
      );
    }

    return _UpdateCopy(
      title: forceUpdate ? '需要更新' : '发现新版本',
      subtitle: forceUpdate
          ? '当前版本已停止支持，请先更新后再继续使用。'
          : '服务器已经提供较新版本，你可以现在更新，也可以稍后再处理。',
      versionLabel: '最新版本',
      currentVersionLabel: '当前版本',
      notesLabel: '更新内容',
      laterLabel: '稍后',
      updateLabel: '立即更新',
      noLinkHint: '当前还没有可用的下载链接，请联系管理员处理。',
    );
  }
}
