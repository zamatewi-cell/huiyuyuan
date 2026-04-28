class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedBuildNumber,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.downloadUrls,
    required this.downloadSizeBytes,
    required this.downloadSha256,
    required this.downloadContentType,
    required this.releaseNotes,
    required this.publishedAt,
  });

  final String platform;
  final String latestVersion;
  final int latestBuildNumber;
  final int minSupportedBuildNumber;
  final bool forceUpdate;
  final String downloadUrl;
  final List<String> downloadUrls;
  final int? downloadSizeBytes;
  final String downloadSha256;
  final String downloadContentType;
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
    final rawDownloadUrls = json['download_urls'];
    final downloadUrls = rawDownloadUrls is List
        ? rawDownloadUrls
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];
    final legacyDownloadUrl = (json['download_url'] ?? '').toString().trim();
    final effectiveDownloadUrl = downloadUrls.isNotEmpty
        ? downloadUrls.first
        : legacyDownloadUrl;

    return AppUpdateInfo(
      platform: (json['platform'] ?? 'android').toString(),
      latestVersion: (json['latest_version'] ?? '').toString(),
      latestBuildNumber:
          int.tryParse('${json['latest_build_number'] ?? 0}') ?? 0,
      minSupportedBuildNumber:
          int.tryParse('${json['min_supported_build_number'] ?? 0}') ?? 0,
      forceUpdate: json['force_update'] == true,
      downloadUrl: effectiveDownloadUrl,
      downloadUrls: downloadUrls.isNotEmpty
          ? downloadUrls
          : (legacyDownloadUrl.isEmpty ? <String>[] : <String>[legacyDownloadUrl]),
      downloadSizeBytes:
          int.tryParse('${json['download_size_bytes'] ?? ''}'),
      downloadSha256: (json['download_sha256'] ?? '').toString().trim(),
      downloadContentType:
          (json['download_content_type'] ?? '').toString().trim(),
      releaseNotes: notes,
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
    );
  }

  bool hasNewerBuildThan(int currentBuildNumber) =>
      latestBuildNumber > currentBuildNumber;

  bool requiresImmediateUpdate(int currentBuildNumber) =>
      forceUpdate || minSupportedBuildNumber > currentBuildNumber;
}
