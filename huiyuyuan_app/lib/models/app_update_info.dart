class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedBuildNumber,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });

  final String platform;
  final String latestVersion;
  final int latestBuildNumber;
  final int minSupportedBuildNumber;
  final bool forceUpdate;
  final String downloadUrl;
  final List<String> releaseNotes;
  final DateTime? publishedAt;

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['release_notes'];
    final notes = rawNotes is List
        ? rawNotes
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];

    return AppUpdateInfo(
      platform: (json['platform'] ?? 'android').toString(),
      latestVersion: (json['latest_version'] ?? '').toString(),
      latestBuildNumber:
          int.tryParse('${json['latest_build_number'] ?? 0}') ?? 0,
      minSupportedBuildNumber:
          int.tryParse('${json['min_supported_build_number'] ?? 0}') ?? 0,
      forceUpdate: json['force_update'] == true,
      downloadUrl: (json['download_url'] ?? '').toString(),
      releaseNotes: notes,
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
    );
  }

  bool hasNewerBuildThan(int currentBuildNumber) =>
      latestBuildNumber > currentBuildNumber;

  bool requiresImmediateUpdate(int currentBuildNumber) =>
      forceUpdate || minSupportedBuildNumber > currentBuildNumber;
}
