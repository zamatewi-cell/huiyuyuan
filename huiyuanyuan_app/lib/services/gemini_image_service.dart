/// 汇玉源 - 图片分析服务（通过后端代理到 OpenRouter）
///
/// 功能:
/// - 商品图片识别
/// - 珠宝材质分析
/// - 图片质量评估
/// - AI描述生成
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_service.dart';

/// 图片分析结果
class ImageAnalysisResult {
  final bool success;
  final String? description;
  final String? material;
  final String? category;
  final List<String>? tags;
  final double? qualityScore;
  final String? suggestion;
  final String? message;

  ImageAnalysisResult({
    required this.success,
    this.description,
    this.material,
    this.category,
    this.tags,
    this.qualityScore,
    this.suggestion,
    this.message,
  });

  factory ImageAnalysisResult.success({
    required String description,
    String? material,
    String? category,
    List<String>? tags,
    double? qualityScore,
    String? suggestion,
  }) {
    return ImageAnalysisResult(
      success: true,
      description: description,
      material: material,
      category: category,
      tags: tags,
      qualityScore: qualityScore,
      suggestion: suggestion,
    );
  }

  factory ImageAnalysisResult.error(String message) {
    return ImageAnalysisResult(
      success: false,
      message: message,
    );
  }
}

/// OpenRouter 图片服务
///
/// 保留旧类名，避免影响现有界面层引用。
class GeminiImageService {
  static final GeminiImageService _instance = GeminiImageService._internal();
  factory GeminiImageService() => _instance;
  GeminiImageService._internal();

  final ApiService _apiService = ApiService();
  final Dio _downloadDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// 初始化
  ///
  /// 兼容旧调用，当前无需显式初始化。
  void initialize([String? apiKey]) {}

  Future<ImageAnalysisResult> analyzeProductImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ImageAnalysisResult.error('图片不存在');
      }

      final bytes = await file.readAsBytes();
      return analyzeProductImageBytes(bytes, _fileNameFromPath(imagePath));
    } catch (e) {
      return ImageAnalysisResult.error('分析失败: $e');
    }
  }

  /// 分析商品图片字节流 (用于全平台支持)
  Future<ImageAnalysisResult> analyzeProductImageBytes(
      Uint8List bytes, String filename) async {
    try {
      final result = await _apiService.uploadBytes<Map<String, dynamic>>(
        '/api/ai/analyze-image',
        bytes: bytes,
        fileName: filename,
        fromJson: (data) => Map<String, dynamic>.from(data as Map),
      );

      if (!result.success || result.data == null) {
        return ImageAnalysisResult.error(result.message ?? '图片分析失败');
      }

      return _parseBackendResponse(result.data!);
    } catch (e) {
      return ImageAnalysisResult.error('分析失败: $e');
    }
  }

  /// 分析远程图片URL
  Future<ImageAnalysisResult> analyzeImageUrl(String imageUrl) async {
    try {
      final response = await _downloadDio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return ImageAnalysisResult.error('图片下载失败');
      }

      return analyzeProductImageBytes(
        Uint8List.fromList(bytes),
        _fileNameFromPath(Uri.tryParse(imageUrl)?.path ?? imageUrl),
      );
    } catch (e) {
      return ImageAnalysisResult.error('分析失败: $e');
    }
  }

  /// 生成商品描述
  Future<String?> generateProductDescription({
    required String imagePath,
    String? productName,
    String? material,
    String? style,
  }) async {
    final analysis = await analyzeProductImage(imagePath);
    if (!analysis.success || analysis.description == null) {
      return null;
    }

    final buffer = StringBuffer();
    if (productName != null && productName.isNotEmpty) {
      buffer.write('$productName：');
    }
    buffer.write(analysis.description);

    final finalMaterial = material ?? analysis.material;
    if (finalMaterial != null && finalMaterial.isNotEmpty) {
      buffer.write(' 材质判断为$finalMaterial。');
    }
    if (style != null && style.isNotEmpty) {
      buffer.write(' 风格建议：$style。');
    }
    if (analysis.suggestion != null && analysis.suggestion!.isNotEmpty) {
      buffer.write(' 拍摄建议：${analysis.suggestion}。');
    }

    return buffer.toString().trim();
  }

  /// 识别珠宝材质
  Future<Map<String, dynamic>?> identifyMaterial(String imagePath) async {
    final analysis = await analyzeProductImage(imagePath);
    if (!analysis.success) {
      return null;
    }

    return {
      'primary_material': analysis.material,
      'secondary_materials': const <String>[],
      'confidence': analysis.material == null ? 0.0 : 0.7,
      'characteristics': analysis.tags ?? const <String>[],
      'origin_guess': null,
    };
  }

  /// 评估图片质量
  Future<Map<String, dynamic>?> assessImageQuality(String imagePath) async {
    final analysis = await analyzeProductImage(imagePath);
    if (!analysis.success) {
      return null;
    }

    return {
      'overall_score': ((analysis.qualityScore ?? 0) * 100).round(),
      'clarity_score': analysis.qualityScore ?? 0,
      'lighting_score': analysis.qualityScore ?? 0,
      'composition_score': analysis.qualityScore ?? 0,
      'background_score': analysis.qualityScore ?? 0,
      'issues': const <String>[],
      'improvements': analysis.suggestion == null
          ? const <String>[]
          : [analysis.suggestion!],
    };
  }

  ImageAnalysisResult _parseBackendResponse(Map<String, dynamic> payload) {
    try {
      final analysis = payload['analysis'];
      final raw = _stringOrNull(payload['raw']);

      if (analysis is Map) {
        final data = Map<String, dynamic>.from(analysis);
        final description =
            _stringOrNull(data['description']) ?? raw ?? '图片分析完成';

        return ImageAnalysisResult.success(
          description: description,
          material: _stringOrNull(data['material']),
          category: _stringOrNull(data['category']),
          tags: _toStringList(data['tags']),
          qualityScore: _toDouble(data['quality_score']),
          suggestion: _stringOrNull(data['suggestion']),
        );
      }

      if (raw != null && raw.isNotEmpty) {
        return ImageAnalysisResult.success(description: raw);
      }

      return ImageAnalysisResult.error('无分析结果');
    } catch (e) {
      return ImageAnalysisResult.error('解析响应失败: $e');
    }
  }

  String _fileNameFromPath(String path) {
    final segments = path.split(RegExp(r'[\\/]'));
    final filename =
        segments.isEmpty ? '' : segments.where((part) => part.isNotEmpty).last;
    return filename.isEmpty ? 'image.jpg' : filename;
  }

  String? _stringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  List<String>? _toStringList(dynamic value) {
    if (value is! List) {
      return null;
    }

    final items = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return items.isEmpty ? null : items;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
