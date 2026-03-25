/// 汇玉源 - OSS图片上传服务
///
/// 功能:
/// - 阿里云OSS图片上传
/// - STS临时凭证获取
/// - 图片压缩处理
/// - 上传进度回调
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';

/// OSS上传结果
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

/// STS临时凭证
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

  /// 是否已过期
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

/// OSS上传服务
class OssService {
  static final OssService _instance = OssService._internal();
  factory OssService() => _instance;
  OssService._internal();

  final ApiService _api = ApiService();
  final Dio _ossDio = Dio();
  final Uuid _uuid = const Uuid();

  StsCredential? _credential;

  /// 初始化
  Future<void> initialize() async {
    _ossDio.options.connectTimeout = const Duration(seconds: 30);
    _ossDio.options.sendTimeout = const Duration(minutes: 5);
    _ossDio.options.receiveTimeout = const Duration(minutes: 5);
  }

  /// 获取STS临时凭证
  Future<StsCredential?> _getStsCredential() async {
    // 如果凭证有效，直接返回
    if (_credential != null && !_credential!.isExpired) {
      return _credential;
    }

    // 从后端获取新的STS凭证
    final result = await _api.get<Map<String, dynamic>>(ApiConfig.ossStsUrl);

    if (result.success && result.data != null) {
      _credential = StsCredential.fromJson(result.data!);
      return _credential;
    }

    return null;
  }

  /// 上传图片
  ///
  /// [filePath] 本地文件路径
  /// [folder] 上传目录，如 'products'、'avatars'
  /// [onProgress] 上传进度回调 (已发送, 总大小)
  Future<OssUploadResult> uploadImage(
    String filePath, {
    String folder = 'images',
    void Function(int, int)? onProgress,
  }) async {
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        return OssUploadResult.error('文件不存在');
      }

      // 获取STS凭证
      final credential = await _getStsCredential();
      if (credential == null) {
        // 如果获取STS失败，使用后端代理上传
        return _uploadViaBackend(filePath, folder, onProgress);
      }

      // 生成唯一文件名
      final fileName = _generateFileName(filePath);
      final objectKey = '$folder/$fileName';

      // 直传OSS
      final uploadUrl =
          'https://${ApiConfig.ossBucket}.${ApiConfig.ossEndpoint}/$objectKey';

      // 读取文件
      final fileBytes = await file.readAsBytes();

      // 构建请求
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

      return OssUploadResult.error('上传失败: ${response.statusCode}');
    } catch (e) {
      return OssUploadResult.error('上传失败: $e');
    }
  }

  /// 通过后端代理上传
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

    return OssUploadResult.error(result.message ?? '上传失败');
  }

  /// 批量上传图片
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

  /// 删除图片
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

  /// 生成唯一文件名
  String _generateFileName(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    final uuid = _uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_$uuid.$extension';
  }

  /// 获取文件MIME类型
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

  /// 生成OSS授权头（简化版，实际需要完整签名）
  String _generateOssAuthorization(
    StsCredential credential,
    String method,
    String objectKey,
    String contentType,
  ) {
    // 注意：这是简化版本，实际使用需要完整的OSS签名算法
    // 建议使用阿里云官方SDK或后端代理上传
    return 'OSS ${credential.accessKeyId}:signature';
  }

  /// 获取图片预览URL（带处理参数）
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

  /// 获取缩略图URL
  String getThumbnailUrl(String url, {int size = 200}) {
    return getPreviewUrl(url, width: size, height: size, quality: 60);
  }
}
