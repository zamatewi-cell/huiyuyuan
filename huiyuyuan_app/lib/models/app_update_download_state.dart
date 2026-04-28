class AppUpdateDownloadState {
  const AppUpdateDownloadState({
    required this.status,
    this.downloadId,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.buildNumber = 0,
    this.version = '',
    this.message,
  });

  final AppUpdateDownloadStatus status;
  final int? downloadId;
  final int progress;
  final int downloadedBytes;
  final int totalBytes;
  final int buildNumber;
  final String version;
  final String? message;

  bool get isActiveDownload =>
      status == AppUpdateDownloadStatus.queued ||
      status == AppUpdateDownloadStatus.running ||
      status == AppUpdateDownloadStatus.paused;

  bool get canInstall => status == AppUpdateDownloadStatus.successful;

  bool get requiresInstallPermission =>
      status == AppUpdateDownloadStatus.permissionRequired;

  bool get shouldShowFailure => status == AppUpdateDownloadStatus.failed;

  factory AppUpdateDownloadState.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const AppUpdateDownloadState(status: AppUpdateDownloadStatus.idle);
    }

    return AppUpdateDownloadState(
      status: AppUpdateDownloadStatusX.fromWireValue(
        (json['status'] ?? '').toString(),
      ),
      downloadId: _parseNullableInt(json['downloadId'] ?? json['download_id']),
      progress: _parseInt(json['progress']),
      downloadedBytes:
          _parseInt(json['downloadedBytes'] ?? json['downloaded_bytes']),
      totalBytes: _parseInt(json['totalBytes'] ?? json['total_bytes']),
      buildNumber: _parseInt(json['buildNumber'] ?? json['build_number']),
      version: (json['version'] ?? '').toString(),
      message: (json['message'] ?? '').toString().trim().isEmpty
          ? null
          : json['message'].toString(),
    );
  }

  static int _parseInt(Object? value) => _parseNullableInt(value) ?? 0;

  static int? _parseNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}

enum AppUpdateDownloadStatus {
  idle,
  external,
  queued,
  running,
  paused,
  successful,
  installing,
  permissionRequired,
  failed,
  unavailable,
}

extension AppUpdateDownloadStatusX on AppUpdateDownloadStatus {
  static AppUpdateDownloadStatus fromWireValue(String value) {
    switch (value) {
      case 'external':
        return AppUpdateDownloadStatus.external;
      case 'queued':
        return AppUpdateDownloadStatus.queued;
      case 'running':
        return AppUpdateDownloadStatus.running;
      case 'paused':
        return AppUpdateDownloadStatus.paused;
      case 'successful':
        return AppUpdateDownloadStatus.successful;
      case 'installing':
        return AppUpdateDownloadStatus.installing;
      case 'permission_required':
        return AppUpdateDownloadStatus.permissionRequired;
      case 'failed':
        return AppUpdateDownloadStatus.failed;
      case 'unavailable':
        return AppUpdateDownloadStatus.unavailable;
      case 'idle':
      default:
        return AppUpdateDownloadStatus.idle;
    }
  }
}
