/// 汇玉源 - Gemini图片分析服务
///
/// 功能:
/// - 商品图片识别
/// - 珠宝材质分析
/// - 图片质量评估
/// - AI描述生成
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

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

/// Gemini图片服务
class GeminiImageService {
  static final GeminiImageService _instance = GeminiImageService._internal();
  factory GeminiImageService() => _instance;
  GeminiImageService._internal();

  late final Dio _dio;
  String? _apiKey;
  bool _initialized = false;

  /// 初始化
  ///
  /// [apiKey] Gemini API密钥
  void initialize(String apiKey) {
    if (_initialized && _apiKey == apiKey) return;

    _apiKey = apiKey;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.geminiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _initialized = true;
  }

  /// 分析商品图片
  ///
  /// [imagePath] 本地图片路径
  Future<ImageAnalysisResult> analyzeProductImage(String imagePath) async {
    if (!_initialized || _apiKey == null) {
      return ImageAnalysisResult.error('服务未初始化');
    }

    try {
      // 读取图片并转为Base64
      final file = File(imagePath);
      if (!await file.exists()) {
        return ImageAnalysisResult.error('图片不存在');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imagePath);

      // 构建请求
      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''请分析这张珠宝商品图片，提供以下信息（以JSON格式返回）：
{
  "description": "详细的商品描述，包括外观、工艺、特点等",
  "material": "判断的材质类型，如和田玉、翡翠、黄金等",
  "category": "商品分类，如手链、吊坠、戒指、手镯、项链、耳饰",
  "tags": ["标签1", "标签2", "标签3"],
  "quality_score": 0.0到1.0之间的图片质量分数,
  "suggestion": "改进建议，如拍摄角度、光线等"
}

请确保返回的是有效的JSON格式。''',
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 1024,
          },
        },
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      return ImageAnalysisResult.error('网络请求失败: ${e.message}');
    } catch (e) {
      return ImageAnalysisResult.error('分析失败: $e');
    }
  }

  /// 分析商品图片字节流 (用于全平台支持)
  Future<ImageAnalysisResult> analyzeProductImageBytes(
      Uint8List bytes, String filename) async {
    if (!_initialized || _apiKey == null) {
      return ImageAnalysisResult.error('服务未初始化');
    }

    try {
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(filename);

      // 构建请求
      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''请分析这张珠宝商品图片，提供以下信息（以JSON格式返回）：
{
  "description": "详细的商品描述，包括外观、工艺、特点等",
  "material": "判断的材质类型，如和田玉、翡翠、黄金等",
  "category": "商品分类，如手链、吊坠、戒指、手镯、项链、耳饰",
  "tags": ["标签1", "标签2", "标签3"],
  "quality_score": 0.0到1.0之间的图片质量分数,
  "suggestion": "改进建议，如拍摄角度、光线等"
}

请确保返回的是有效的JSON格式。''',
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 1024,
          },
        },
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      // 主模型失败时回退到 gemini-1.5-flash
      try {
        final base64Fallback = base64Encode(bytes);
        final mimeTypeFallback = _getMimeType(filename);
        final fallback = await _dio.post(
          '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
          data: {
            'contents': [
              {
                'parts': [
                  {'text': '请用中文详细分析这张珠宝图片：材质（如翡翠/和田玉/黄金等）、品类（手镯/戒指/项链等）、外观特征和工艺。'},
                  {'inline_data': {'mime_type': mimeTypeFallback, 'data': base64Fallback}},
                ],
              },
            ],
          },
        );
        final text = fallback.data?['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return ImageAnalysisResult.success(description: text);
        }
        return ImageAnalysisResult.error('图片分析失败，请重试');
      } catch (_) {
        return ImageAnalysisResult.error('网络请求失败: ${e.message}');
      }
    } catch (e) {
      return ImageAnalysisResult.error('分析失败: $e');
    }
  }

  /// 分析远程图片URL
  Future<ImageAnalysisResult> analyzeImageUrl(String imageUrl) async {
    if (!_initialized || _apiKey == null) {
      return ImageAnalysisResult.error('服务未初始化');
    }

    try {
      // 使用URL直接分析（如果Gemini支持）
      // 否则先下载再分析
      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''请分析这张珠宝商品图片，提供以下信息（以JSON格式返回）：
{
  "description": "详细的商品描述",
  "material": "材质类型",
  "category": "商品分类",
  "tags": ["标签数组"],
  "quality_score": 质量分数0-1,
  "suggestion": "改进建议"
}''',
                },
                {
                  'file_data': {
                    'mime_type': 'image/jpeg',
                    'file_uri': imageUrl,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1024,
          },
        },
      );

      return _parseResponse(response.data);
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
    if (!_initialized || _apiKey == null) {
      return null;
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imagePath);

      String prompt = '请为这个珠宝商品生成一段优美的销售描述文案。';
      if (productName != null) prompt += '商品名称：$productName。';
      if (material != null) prompt += '材质：$material。';
      if (style != null) prompt += '风格：$style。';
      prompt += '''
要求：
1. 突出商品的品质和特色
2. 使用优雅、专业的语言
3. 包含寓意和适合场景
4. 控制在100-200字
''';

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 512,
          },
        },
      );

      final text = _extractText(response.data);
      return text;
    } catch (_) {
      return null;
    }
  }

  /// 识别珠宝材质
  Future<Map<String, dynamic>?> identifyMaterial(String imagePath) async {
    if (!_initialized || _apiKey == null) return null;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imagePath);

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''请识别这张图片中珠宝的材质，返回JSON格式：
{
  "primary_material": "主要材质",
  "secondary_materials": ["辅助材质"],
  "confidence": 0.0-1.0的置信度,
  "characteristics": ["材质特征"],
  "origin_guess": "可能的产地"
}''',
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 512,
          },
        },
      );

      final text = _extractText(response.data);
      if (text == null) return null;

      return _parseJsonFromText(text);
    } catch (_) {
      return null;
    }
  }

  /// 评估图片质量
  Future<Map<String, dynamic>?> assessImageQuality(String imagePath) async {
    if (!_initialized || _apiKey == null) return null;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imagePath);

      final response = await _dio.post(
        '/models/${ApiConfig.geminiModel}:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '''请评估这张商品图片的质量，返回JSON格式：
{
  "overall_score": 0-100的总分,
  "clarity_score": 清晰度分数,
  "lighting_score": 光线分数,
  "composition_score": 构图分数,
  "background_score": 背景分数,
  "issues": ["存在的问题"],
  "improvements": ["改进建议"]
}''',
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 512,
          },
        },
      );

      final text = _extractText(response.data);
      if (text == null) return null;

      return _parseJsonFromText(text);
    } catch (_) {
      return null;
    }
  }

  /// 解析Gemini响应
  ImageAnalysisResult _parseResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return ImageAnalysisResult.error('无分析结果');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return ImageAnalysisResult.error('响应格式错误');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        return ImageAnalysisResult.error('无文本内容');
      }

      // 尝试解析JSON
      final json = _parseJsonFromText(text);
      if (json != null) {
        return ImageAnalysisResult.success(
          description: json['description'] ?? text,
          material: json['material'],
          category: json['category'],
          tags: (json['tags'] as List?)?.cast<String>(),
          qualityScore: (json['quality_score'] as num?)?.toDouble(),
          suggestion: json['suggestion'],
        );
      }

      // 如果不是JSON，直接返回文本作为描述
      return ImageAnalysisResult.success(description: text);
    } catch (e) {
      return ImageAnalysisResult.error('解析响应失败: $e');
    }
  }

  /// 从响应中提取文本
  String? _extractText(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      return parts[0]['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 从文本中解析JSON
  Map<String, dynamic>? _parseJsonFromText(String text) {
    try {
      // 尝试直接解析
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // 尝试提取JSON部分
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        try {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  /// 获取MIME类型
  String _getMimeType(String filePath) {
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
        return 'image/jpeg';
    }
  }
}
