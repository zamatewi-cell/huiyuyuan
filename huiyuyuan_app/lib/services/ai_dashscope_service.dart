import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import '../utils/text_sanitizer.dart';

class AIDashScopeService {
  AIDashScopeService({Dio? dio, Dio? proxyDio, ApiService? apiService})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.dashScopeBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {
                  'Authorization': 'Bearer ${AppConfig.dashScopeApiKey}',
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _proxyDio = proxyDio,
        _api = apiService ?? ApiService();

  final Dio _dio;
  final Dio? _proxyDio;
  final ApiService _api;
  String? _lastError;
  int? _lastStatusCode;

  bool get hasDirectAccess => AppConfig.hasValidDashScopeApiKey;

  bool get hasBackendProxy => !ApiConfig.useMockApi;

  bool get isConfigured => hasDirectAccess || hasBackendProxy;

  String? get lastError => _lastError;

  bool get _backendRejected => _lastStatusCode == 401 || _lastStatusCode == 403;

  @visibleForTesting
  Map<String, dynamic> get debugHeaders =>
      Map<String, dynamic>.from(_dio.options.headers);

  Future<String?> createChatCompletion({
    required List<Map<String, String>> messages,
  }) async {
    _lastError = null;
    _lastStatusCode = null;
    final payload = _buildPayload(messages: messages, stream: false);

    if (hasBackendProxy) {
      final proxyResponse = _proxyDio != null
          ? await _requestChat(
              client: _proxyDio!,
              path: ApiConfig.aiChat,
              payload: payload,
              sourceLabel: 'AI proxy',
            )
          : await _requestChatViaApi(
              payload: payload,
              sourceLabel: 'AI proxy',
            );
      if (proxyResponse != null) {
        return proxyResponse;
      }
      if (_backendRejected) {
        return null;
      }
    }

    if (hasDirectAccess) {
      final directResponse = await _requestChat(
        client: _dio,
        path: '/chat/completions',
        payload: payload,
        sourceLabel: 'DashScope',
      );
      if (directResponse != null) {
        return directResponse;
      }
    }

    _lastError ??= _missingConfigMessage();
    return null;
  }

  Future<String?> createChatCompletionStream({
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
  }) async {
    _lastError = null;
    _lastStatusCode = null;
    final payload = _buildPayload(messages: messages, stream: true);

    if (hasBackendProxy) {
      final proxyResponse = _proxyDio != null
          ? await _requestChatStream(
              client: _proxyDio!,
              path: ApiConfig.aiChat,
              payload: payload,
              sourceLabel: 'AI proxy',
              onToken: onToken,
            )
          : await _requestChatStreamViaApi(
              payload: payload,
              sourceLabel: 'AI proxy',
              onToken: onToken,
            );
      if (proxyResponse != null) {
        return proxyResponse;
      }
      if (_backendRejected) {
        return null;
      }
    }

    if (hasDirectAccess) {
      final directResponse = await _requestChatStream(
        client: _dio,
        path: '/chat/completions',
        payload: payload,
        sourceLabel: 'DashScope',
        onToken: onToken,
      );
      if (directResponse != null) {
        return directResponse;
      }
    }

    _lastError ??= _missingConfigMessage();
    return null;
  }

  Map<String, dynamic> _buildPayload({
    required List<Map<String, String>> messages,
    required bool stream,
  }) {
    return {
      'model': AppConfig.dashScopeModel,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
      'stream': stream,
    };
  }

  void _setFailure(String message, {int? statusCode}) {
    _lastError = message;
    _lastStatusCode = statusCode;
  }

  void _clearFailureStatus() {
    _lastStatusCode = null;
  }

  Future<String?> _requestChat({
    required Dio client,
    required String path,
    required Map<String, dynamic> payload,
    required String sourceLabel,
  }) async {
    try {
      final response = await client.post(path, data: payload);
      if (response.statusCode != 200) {
        _setFailure(
          '$sourceLabel request failed: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
        return null;
      }
      _clearFailureStatus();

      final data = _normalizeResponse(response.data);
      final error = sanitizeUtf16((data['error'] ?? '').toString().trim());
      if (error.isNotEmpty) {
        _setFailure(error);
        return null;
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        _setFailure('$sourceLabel returned an empty response.');
        return null;
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = extractTextContent(message?['content']);
      if (content.isEmpty) {
        _setFailure('$sourceLabel did not return usable content.');
        return null;
      }

      return content;
    } on DioException catch (error) {
      _setFailure(
        _formatDioError(error, sourceLabel),
        statusCode: error.response?.statusCode,
      );
      return null;
    } catch (error) {
      _setFailure('$sourceLabel request failed: $error');
      return null;
    }
  }

  Future<String?> _requestChatViaApi({
    required Map<String, dynamic> payload,
    required String sourceLabel,
  }) async {
    try {
      final result = await _api.post<dynamic>(ApiConfig.aiChat, data: payload);
      if (!result.success || result.data == null) {
        _setFailure(
          result.message ?? '$sourceLabel request failed: empty response',
          statusCode: result.code,
        );
        return null;
      }
      _clearFailureStatus();

      final data = _normalizeResponse(result.data);
      final error = sanitizeUtf16((data['error'] ?? '').toString().trim());
      if (error.isNotEmpty) {
        _setFailure(error);
        return null;
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        _setFailure('$sourceLabel returned an empty response.');
        return null;
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = extractTextContent(message?['content']);
      if (content.isEmpty) {
        _setFailure('$sourceLabel did not return usable content.');
        return null;
      }

      return content;
    } catch (error) {
      _setFailure('$sourceLabel request failed: $error');
      return null;
    }
  }

  Future<String?> _requestChatStream({
    required Dio client,
    required String path,
    required Map<String, dynamic> payload,
    required String sourceLabel,
    required void Function(String token) onToken,
  }) async {
    try {
      final response = await client.post(
        path,
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode != 200) {
        _setFailure(
          '$sourceLabel streaming request failed: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
        return null;
      }
      _clearFailureStatus();

      final stream = response.data.stream as Stream<List<int>>;
      final buffer = StringBuffer();
      var pendingLine = '';

      await for (final chunk in stream) {
        pendingLine += utf8.decode(chunk, allowMalformed: true);

        while (pendingLine.contains('\n')) {
          final newlineIndex = pendingLine.indexOf('\n');
          final line = pendingLine.substring(0, newlineIndex).trim();
          pendingLine = pendingLine.substring(newlineIndex + 1);

          final token = _extractStreamToken(line, sourceLabel: sourceLabel);
          if (token.isEmpty) {
            continue;
          }

          buffer.write(token);
          onToken(token);
        }
      }

      final tailToken =
          _extractStreamToken(pendingLine.trim(), sourceLabel: sourceLabel);
      if (tailToken.isNotEmpty) {
        buffer.write(tailToken);
        onToken(tailToken);
      }

      final result = sanitizeUtf16(buffer.toString());
      if (result.isEmpty) {
        _setFailure('$sourceLabel streaming response was empty.');
        return null;
      }

      return result;
    } on DioException catch (error) {
      _setFailure(
        _formatDioError(error, sourceLabel),
        statusCode: error.response?.statusCode,
      );
      return null;
    } catch (error) {
      _setFailure('$sourceLabel streaming request failed: $error');
      return null;
    }
  }

  Future<String?> _requestChatStreamViaApi({
    required Map<String, dynamic> payload,
    required String sourceLabel,
    required void Function(String token) onToken,
  }) async {
    try {
      final response = await _api.postRaw(
        ApiConfig.aiChat,
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode != 200) {
        _setFailure(
          '$sourceLabel streaming request failed: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
        return null;
      }
      _clearFailureStatus();

      final stream = response.data.stream as Stream<List<int>>;
      final buffer = StringBuffer();
      var pendingLine = '';

      await for (final chunk in stream) {
        pendingLine += utf8.decode(chunk, allowMalformed: true);

        while (pendingLine.contains('\n')) {
          final newlineIndex = pendingLine.indexOf('\n');
          final line = pendingLine.substring(0, newlineIndex).trim();
          pendingLine = pendingLine.substring(newlineIndex + 1);

          final token = _extractStreamToken(line, sourceLabel: sourceLabel);
          if (token.isEmpty) {
            continue;
          }

          buffer.write(token);
          onToken(token);
        }
      }

      final tailToken =
          _extractStreamToken(pendingLine.trim(), sourceLabel: sourceLabel);
      if (tailToken.isNotEmpty) {
        buffer.write(tailToken);
        onToken(tailToken);
      }

      final result = sanitizeUtf16(buffer.toString());
      if (result.isEmpty) {
        _setFailure('$sourceLabel streaming response was empty.');
        return null;
      }

      return result;
    } on DioException catch (error) {
      _setFailure(
        _formatDioError(error, sourceLabel),
        statusCode: error.response?.statusCode,
      );
      return null;
    } catch (error) {
      _setFailure('$sourceLabel streaming request failed: $error');
      return null;
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
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

  String _extractStreamToken(
    String line, {
    required String sourceLabel,
  }) {
    if (!line.startsWith('data: ')) {
      return '';
    }

    final data = line.substring(6).trim();
    if (data.isEmpty || data == '[DONE]') {
      return '';
    }

    try {
      final jsonData = json.decode(data) as Map<String, dynamic>;
      final error = sanitizeUtf16((jsonData['error'] ?? '').toString().trim());
      if (error.isNotEmpty) {
        _lastError = error;
        return '';
      }

      final choices = jsonData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return '';
      }

      final delta = choices[0]['delta'] as Map<String, dynamic>?;
      return sanitizeUtf16(extractTextContent(delta?['content']));
    } catch (_) {
      _lastError ??= '$sourceLabel streaming response could not be parsed.';
      return '';
    }
  }

  String _missingConfigMessage() {
    if (hasBackendProxy) {
      return 'AI proxy is unavailable.';
    }
    final issue = AppConfig.dashScopeApiKeyIssue ?? 'DASHSCOPE_API_KEY missing';
    return 'DashScope is not configured: $issue (${AppConfig.dashScopeApiKeySource})';
  }

  String _formatDioError(DioException error, String sourceLabel) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return '$sourceLabel request failed: HTTP $statusCode';
    }

    final raw = error.error?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return '$sourceLabel network error: $raw';
    }

    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return '$sourceLabel network error: $message';
    }

    return '$sourceLabel network error';
  }
}
