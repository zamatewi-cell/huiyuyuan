/// HuiYuYuan image analysis service proxied through the backend.
///
/// Responsibilities:
/// - Product image recognition
/// - Jewelry material analysis
/// - Image quality evaluation
/// - AI-assisted description generation
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_service.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

/// Image analysis result.
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

/// OpenRouter-backed image service.
///
/// Keeps the legacy class name to avoid breaking existing UI callers.
class GeminiImageService {
  static final GeminiImageService _instance = GeminiImageService._internal();
  factory GeminiImageService() => _instance;
  GeminiImageService._internal();

  final ApiService _apiService = ApiService();
  final Dio _downloadDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Initializes the service.
  ///
  /// Kept for compatibility with older call sites. No explicit setup is
  /// currently required.
  void initialize([String? apiKey]) {}

  Future<ImageAnalysisResult> analyzeProductImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ImageAnalysisResult.error('ai_image_error_not_found'.tr);
      }

      final bytes = await file.readAsBytes();
      return analyzeProductImageBytes(bytes, _fileNameFromPath(imagePath));
    } catch (e) {
      return ImageAnalysisResult.error(
        'ai_image_error_failed_with_detail'.trArgs({'error': e}),
      );
    }
  }

  /// Analyzes raw product image bytes for cross-platform support.
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
        return ImageAnalysisResult.error(
          result.message ?? 'ai_image_error_failed'.tr,
        );
      }

      return _parseBackendResponse(result.data!);
    } catch (e) {
      return ImageAnalysisResult.error(
        'ai_image_error_failed_with_detail'.trArgs({'error': e}),
      );
    }
  }

  /// Analyzes a remote image URL.
  Future<ImageAnalysisResult> analyzeImageUrl(String imageUrl) async {
    try {
      final response = await _downloadDio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return ImageAnalysisResult.error('ai_image_error_download_failed'.tr);
      }

      return analyzeProductImageBytes(
        Uint8List.fromList(bytes),
        _fileNameFromPath(Uri.tryParse(imageUrl)?.path ?? imageUrl),
      );
    } catch (e) {
      return ImageAnalysisResult.error(
        'ai_image_error_failed_with_detail'.trArgs({'error': e}),
      );
    }
  }

  /// Generates a product description from the analyzed image.
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
      buffer.write(
        ' ${'ai_image_description_material'.trArgs({
              'material': finalMaterial
            })}',
      );
    }
    if (style != null && style.isNotEmpty) {
      buffer.write(
        ' ${'ai_image_description_style'.trArgs({'style': style})}',
      );
    }
    if (analysis.suggestion != null && analysis.suggestion!.isNotEmpty) {
      buffer.write(
        ' ${'ai_image_description_shooting'.trArgs({
              'suggestion': analysis.suggestion!,
            })}',
      );
    }

    return buffer.toString().trim();
  }

  /// Identifies jewelry material hints from an image.
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

  /// Evaluates basic image quality signals.
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
        final description = _stringOrNull(data['description']) ??
            raw ??
            'ai_image_analysis_completed'.tr;

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

      return ImageAnalysisResult.error('ai_image_error_no_result'.tr);
    } catch (e) {
      return ImageAnalysisResult.error(
        'ai_image_error_parse_failed_with_detail'.trArgs({'error': e}),
      );
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
