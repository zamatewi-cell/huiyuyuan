/// HuiYuYuan OSS image upload service.
///
/// Responsibilities:
/// - upload images to Alibaba Cloud OSS
/// - fetch temporary STS credentials
/// - support upload progress callbacks
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../l10n/translator_global.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';

/// OSS upload result.
class OssUploadResult {
  final bool success;
  final String? url;
  final String? objectKey;
  final String? message;

  OssUploadResult({
    required this.success,
    this.url,
    this.objectKey,
    this.message,
  });

  factory OssUploadResult.success(String url, String objectKey) {
    return OssUploadResult(
      success: true,
      url: url,
      objectKey: objectKey,
    );
  }

  factory OssUploadResult.error(String message) {
    return OssUploadResult(
      success: false,
      message: message,
    );
  }
}

/// Temporary STS credential.
class StsCredential {
  final String accessKeyId;
  final String accessKeySecret;
  final String securityToken;
  final String expiration;

  StsCredential({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.securityToken,
    required this.expiration,
  });

  factory StsCredential.fromJson(Map<String, dynamic> json) {
    return StsCredential(
      accessKeyId: jsonAsString(json['access_key_id']),
      accessKeySecret: jsonAsString(json['access_key_secret']),
      securityToken: jsonAsString(json['security_token']),
      expiration: jsonAsString(json['expiration']),
    );
  }

  /// Whether the credential is expired.
  bool get isExpired {
    try {
      final expireTime = DateTime.parse(expiration);
      return DateTime.now()
          .isAfter(expireTime.subtract(const Duration(minutes: 5)));
    } catch (_) {
      return true;
    }
  }
}

/// OSS upload service.
class OssService {
  static final OssService _instance = OssService._internal();
  factory OssService() => _instance;
  OssService._internal();

  final ApiService _api = ApiService();
  final Dio _ossDio = Dio();
  final Uuid _uuid = const Uuid();

  StsCredential? _credential;

  /// Initializes upload client timeouts.
  Future<void> initialize() async {
    _ossDio.options.connectTimeout = const Duration(seconds: 30);
    _ossDio.options.sendTimeout = const Duration(minutes: 5);
    _ossDio.options.receiveTimeout = const Duration(minutes: 5);
  }

  /// Fetches a valid STS credential.
  Future<StsCredential?> _getStsCredential() async {
    // Reuse the cached credential while it is still valid.
    if (_credential != null && !_credential!.isExpired) {
      return _credential;
    }

    // Fetch a new credential from the backend.
    final result = await _api.get<Map<String, dynamic>>(ApiConfig.ossStsUrl);

    if (result.success && result.data != null) {
      _credential = StsCredential.fromJson(result.data!);
      return _credential;
    }

    return null;
  }

  /// Uploads an image.
  ///
  /// [filePath] local file path
  /// [folder] upload folder such as `products` or `avatars`
  /// [onProgress] upload progress callback `(sent, total)`
  Future<OssUploadResult> uploadImage(
    String filePath, {
    String folder = 'images',
    void Function(int, int)? onProgress,
  }) async {
    try {
      // Make sure the file exists before uploading.
      final file = File(filePath);
      if (!await file.exists()) {
        return OssUploadResult.error(_t('oss_error_file_missing'));
      }

      // Resolve a valid STS credential.
      final credential = await _getStsCredential();
      if (credential == null) {
        // Fall back to backend-proxied upload when STS is unavailable.
        return _uploadViaBackend(filePath, folder, onProgress);
      }

      // Generate a unique file name.
      final fileName = _generateFileName(filePath);
      final objectKey = '$folder/$fileName';

      // Upload directly to OSS.
      final uploadUrl =
          'https://${ApiConfig.ossBucket}.${ApiConfig.ossEndpoint}/$objectKey';

      // Read file bytes.
      final fileBytes = await file.readAsBytes();

      // Build the upload request.
      final response = await _ossDio.put(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            'Content-Type': _getContentType(filePath),
            'Content-Length': fileBytes.length,
            'x-oss-security-token': credential.securityToken,
            'Authorization': _generateOssAuthorization(
              credential,
              'PUT',
              objectKey,
              _getContentType(filePath),
            ),
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = '${ApiConfig.ossBaseUrl}/$objectKey';
        return OssUploadResult.success(url, objectKey);
      }

      return OssUploadResult.error(
          _t('oss_error_upload_failed_status', params: {
        'status': response.statusCode ?? '-',
      }));
    } catch (e) {
      return OssUploadResult.error(_t('oss_error_upload_failed', params: {
        'error': e,
      }));
    }
  }

  /// Uploads through the backend proxy.
  Future<OssUploadResult> _uploadViaBackend(
    String filePath,
    String folder,
    void Function(int, int)? onProgress,
  ) async {
    final fileName = _generateFileName(filePath);

    final result = await _api.upload<Map<String, dynamic>>(
      ApiConfig.uploadImage,
      filePath: filePath,
      fileName: fileName,
      extraData: {'folder': folder},
      onProgress: onProgress,
    );

    if (result.success && result.data != null) {
      return OssUploadResult.success(
        jsonAsString(result.data!['url']),
        jsonAsString(result.data!['object_key']),
      );
    }

    return OssUploadResult.error(
        result.message ?? _t('oss_error_upload_generic'));
  }

  /// Uploads multiple images.
  Future<List<OssUploadResult>> uploadImages(
    List<String> filePaths, {
    String folder = 'images',
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <OssUploadResult>[];

    for (int i = 0; i < filePaths.length; i++) {
      final result = await uploadImage(filePaths[i], folder: folder);
      results.add(result);
      onProgress?.call(i + 1, filePaths.length);
    }

    return results;
  }

  /// Deletes an uploaded image.
  Future<bool> deleteImage(String objectKey) async {
    try {
      final credential = await _getStsCredential();
      if (credential == null) {
        return false;
      }

      final deleteUrl =
          'https://${ApiConfig.ossBucket}.${ApiConfig.ossEndpoint}/$objectKey';

      final response = await _ossDio.delete(
        deleteUrl,
        options: Options(
          headers: {
            'x-oss-security-token': credential.securityToken,
            'Authorization': _generateOssAuthorization(
              credential,
              'DELETE',
              objectKey,
              '',
            ),
          },
        ),
      );

      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Generates a unique file name.
  String _generateFileName(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    final uuid = _uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_$uuid.$extension';
  }

  /// Returns the file MIME type.
  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generates a simplified OSS authorization header.
  String _generateOssAuthorization(
    StsCredential credential,
    String method,
    String objectKey,
    String contentType,
  ) {
    // This is a simplified placeholder. Production uploads should use the
    // full OSS signing algorithm or the official SDK/backend proxy.
    return 'OSS ${credential.accessKeyId}:signature';
  }

  /// Returns a preview URL with image processing parameters.
  String getPreviewUrl(String url,
      {int? width, int? height, int quality = 80}) {
    if (!url.contains(ApiConfig.ossBucket)) {
      return url;
    }

    final params = <String>[];
    params.add('x-oss-process=image');

    if (width != null || height != null) {
      if (width != null && height != null) {
        params.add('resize,m_fill,w_$width,h_$height');
      } else if (width != null) {
        params.add('resize,w_$width');
      } else {
        params.add('resize,h_$height');
      }
    }

    params.add('quality,q_$quality');
    params.add('format,webp');

    return '$url?${params.join('/')}';
  }

  /// Returns a thumbnail URL.
  String getThumbnailUrl(String url, {int size = 200}) {
    return getPreviewUrl(url, width: size, height: size, quality: 60);
  }

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }
}
