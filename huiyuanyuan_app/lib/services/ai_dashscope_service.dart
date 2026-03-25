import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../utils/text_sanitizer.dart';

class AIDashScopeService {
  AIDashScopeService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.dashScopeBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'Authorization': 'Bearer ${AppConfig.dashScopeApiKey}',
                'Content-Type': 'application/json',
              },
            ));

  final Dio _dio;
  String? _lastError;

  bool get isConfigured => AppConfig.hasValidDashScopeApiKey;

  String? get lastError => _lastError;

  @visibleForTesting
  Map<String, dynamic> get debugHeaders =>
      Map<String, dynamic>.from(_dio.options.headers);

  Future<String?> createChatCompletion({
    required List<Map<String, String>> messages,
  }) async {
    _lastError = null;
    if (!isConfigured) {
      _lastError = _missingConfigMessage();
      return null;
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AppConfig.dashScopeModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
          'stream': false,
        },
      );

      if (response.statusCode != 200) {
        _lastError = 'DashScope request failed: HTTP ${response.statusCode}';
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        _lastError = 'DashScope returned an empty response.';
        return null;
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = extractTextContent(message?['content']);
      if (content.isEmpty) {
        _lastError = 'DashScope did not return usable content.';
        return null;
      }

      return content;
    } on DioException catch (error) {
      _lastError = _formatDioError(error);
      return null;
    } catch (error) {
      _lastError = 'DashScope request failed: $error';
      return null;
    }
  }

  Future<String?> createChatCompletionStream({
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
  }) async {
    _lastError = null;
    if (!isConfigured) {
      _lastError = _missingConfigMessage();
      return null;
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AppConfig.dashScopeModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode != 200) {
        _lastError =
            'DashScope streaming request failed: HTTP ${response.statusCode}';
        return null;
      }

      final stream = response.data.stream as Stream<List<int>>;
      final buffer = StringBuffer();
      var pendingLine = '';

      await for (final chunk in stream) {
        pendingLine += utf8.decode(chunk, allowMalformed: true);

        while (pendingLine.contains('\n')) {
          final newlineIndex = pendingLine.indexOf('\n');
          final line = pendingLine.substring(0, newlineIndex).trim();
          pendingLine = pendingLine.substring(newlineIndex + 1);

          final token = _extractStreamToken(line);
          if (token.isEmpty) {
            continue;
          }

          buffer.write(token);
          onToken(token);
        }
      }

      final tailToken = _extractStreamToken(pendingLine.trim());
      if (tailToken.isNotEmpty) {
        buffer.write(tailToken);
        onToken(tailToken);
      }

      final result = sanitizeUtf16(buffer.toString());
      if (result.isEmpty) {
        _lastError = 'DashScope streaming response was empty.';
        return null;
      }

      return result;
    } on DioException catch (error) {
      _lastError = _formatDioError(error);
      return null;
    } catch (error) {
      _lastError = 'DashScope streaming request failed: $error';
      return null;
    }
  }

  String extractTextContent(dynamic content) {
    if (content is String) {
      return sanitizeUtf16(content);
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map) {
          final text = item['text'];
          if (text is String) {
            buffer.write(sanitizeUtf16(text));
          }
        }
      }
      return buffer.toString();
    }

    return '';
  }

  String _extractStreamToken(String line) {
    if (!line.startsWith('data: ')) {
      return '';
    }

    final data = line.substring(6).trim();
    if (data.isEmpty || data == '[DONE]') {
      return '';
    }

    try {
      final jsonData = json.decode(data) as Map<String, dynamic>;
      final choices = jsonData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return '';
      }

      final delta = choices[0]['delta'] as Map<String, dynamic>?;
      return sanitizeUtf16(extractTextContent(delta?['content']));
    } catch (_) {
      return '';
    }
  }

  String _missingConfigMessage() {
    final issue = AppConfig.dashScopeApiKeyIssue ?? 'DASHSCOPE_API_KEY missing';
    return 'DashScope is not configured: $issue (${AppConfig.dashScopeApiKeySource})';
  }

  String _formatDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'DashScope request failed: HTTP $statusCode';
    }

    final raw = error.error?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return 'DashScope network error: $raw';
    }

    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return 'DashScope network error: $message';
    }

    return 'DashScope network error';
  }
}
