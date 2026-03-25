library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import 'storage_service.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;

  ApiResult({
    required this.success,
    this.data,
    this.message,
    this.code,
  });

  factory ApiResult.success(T data, {String? message}) {
    return ApiResult(
      success: true,
      data: data,
      message: message,
      code: 200,
    );
  }

  factory ApiResult.error(String message, {int? code}) {
    return ApiResult(
      success: false,
      message: message,
      code: code ?? 500,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  @visibleForTesting
  ApiService.forTesting()
      : _dio = Dio(),
        _initialized = true,
        _token = null,
        _refreshRetryCount = 0;

  late final Dio _dio;
  bool _initialized = false;
  String? _token;
  int _refreshRetryCount = 0;

  static const int _maxRefreshRetries = 2;

  final StorageService _storage = StorageService();

  Future<void> initialize() async {
    if (_initialized) {
      _dio.options.baseUrl = ApiConfig.apiUrl;
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
        headers: ApiHeaders.basic,
      ),
    );

    _dio.interceptors.add(_createInterceptor());
    await _loadToken();
    _initialized = true;
  }

  Interceptor _createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null &&
            !options.headers.containsKey(ApiHeaders.authorization)) {
          options.headers[ApiHeaders.authorization] = 'Bearer $_token';
        }

        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            _refreshRetryCount < _maxRefreshRetries) {
          _refreshRetryCount++;
          final refreshed = await _refreshToken();
          if (refreshed) {
            try {
              final retryResponse = await _retry(error.requestOptions);
              _refreshRetryCount = 0;
              handler.resolve(retryResponse);
              return;
            } catch (_) {}
          }
          await _clearToken();
        } else if (error.response?.statusCode == 401) {
          _refreshRetryCount = 0;
          await _clearToken();
        }

        _logError(error);
        handler.next(error);
      },
    );
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        ApiHeaders.authorization: 'Bearer $_token',
      },
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post(
        ApiConfig.authRefresh,
        options: Options(
          headers: {
            ApiHeaders.authorization: 'Bearer $refreshToken',
          },
        ),
      );

      final rawData = response.data;
      final data = rawData is Map<String, dynamic>
          ? rawData
          : (rawData is Map ? Map<String, dynamic>.from(rawData) : null);
      if (response.statusCode == 200 && data != null && data['token'] != null) {
        _token = data['token'].toString();
        await _saveToken(_token!);

        final newRefreshToken = (data['refresh_token'] ?? '').toString();
        if (newRefreshToken.isNotEmpty) {
          await _storage.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _saveToken(token);
  }

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  Future<void> _loadToken() async {
    final user = await _storage.getUser();
    _token = user == null ? null : jsonAsNullableString(user['token']);
  }

  Future<void> _saveToken(String token) async {
    await _storage.saveToken(token);
    final user = await _storage.getUser() ?? <String, dynamic>{};
    user['token'] = token;
    await _storage.saveUser(user);
  }

  Future<void> _clearToken() async {
    _token = null;
    await _storage.clearUser();
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (ApiConfig.useMockApi) return ApiResult.error('Mock模式', code: -1);
    await _ensureInitialized();

    try {
      final response = await _dio.get(path, queryParameters: params);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (ApiConfig.useMockApi) return ApiResult.error('Mock模式', code: -1);
    await _ensureInitialized();

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (ApiConfig.useMockApi) return ApiResult.error('Mock模式', code: -1);
    await _ensureInitialized();

    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (ApiConfig.useMockApi) return ApiResult.error('Mock模式', code: -1);
    await _ensureInitialized();

    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<ApiResult<T>> upload<T>(
    String path, {
    required String filePath,
    required String fileName,
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    void Function(int, int)? onProgress,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
        ...?extraData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {ApiHeaders.contentType: ApiHeaders.multipartContent},
          sendTimeout: const Duration(milliseconds: ApiConfig.uploadTimeout),
        ),
        onSendProgress: onProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<ApiResult<T>> uploadBytes<T>(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(bytes, filename: fileName),
        ...?extraData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {ApiHeaders.contentType: ApiHeaders.multipartContent},
          sendTimeout: const Duration(milliseconds: ApiConfig.uploadTimeout),
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  ApiResult<T> _handleResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      if (fromJson != null) {
        try {
          final parsed = fromJson(data);
          return ApiResult.success(parsed);
        } catch (error) {
          return ApiResult.error('数据解析失败: $error');
        }
      }

      String? message;
      if (data is Map) {
        message = jsonAsNullableString(data['message']);
      }

      return ApiResult.success(data as T, message: message);
    }

    final responseMap = jsonAsNullableMap(response.data);
    return ApiResult.error(
      responseMap == null
          ? '请求失败'
          : jsonAsString(responseMap['message'], fallback: '请求失败'),
      code: response.statusCode,
    );
  }

  ApiResult<T> _handleError<T>(DioException error) {
    String message;
    int code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时，请检查网络';
        code = -1;
        break;
      case DioExceptionType.sendTimeout:
        message = '发送超时，请稍后重试';
        code = -2;
        break;
      case DioExceptionType.receiveTimeout:
        message = '响应超时，请稍后重试';
        code = -3;
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        code = statusCode;
        final responseData = error.response?.data;
        final detailMessage = responseData is Map
            ? (responseData['detail'] ?? responseData['message'])?.toString()
            : null;
        if (statusCode == 401) {
          message = detailMessage ?? '登录已过期，请重新登录';
        } else if (statusCode == 403) {
          message = detailMessage ?? '没有权限执行此操作';
        } else if (statusCode == 404) {
          message = detailMessage ?? '请求的资源不存在';
        } else if (statusCode >= 500) {
          message = detailMessage ?? '服务器错误，请稍后重试';
        } else {
          message = detailMessage ?? '请求失败';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        code = -4;
        break;
      case DioExceptionType.connectionError:
        message = '网络连接失败，请检查后端地址或服务状态';
        code = -5;
        break;
      case DioExceptionType.unknown:
        final rawError = error.error?.toString().trim();
        if (rawError != null && rawError.isNotEmpty) {
          final normalized = rawError.toLowerCase();
          if (normalized.contains('socketexception') ||
              normalized.contains('failed host lookup') ||
              normalized.contains('connection refused') ||
              normalized.contains('network is unreachable') ||
              normalized.contains('timed out')) {
            message = '网络连接失败，请检查后端地址或服务状态';
            code = -5;
            break;
          }
          message = '网络请求异常: $rawError';
        } else {
          message = '网络请求异常，请检查后端地址或服务状态';
        }
        code = -99;
        break;
      default:
        final fallbackMessage = error.message?.trim();
        if (fallbackMessage == null || fallbackMessage.isEmpty) {
          message = '网络错误，请稍后重试';
        } else {
          message = '网络错误: $fallbackMessage';
        }
        code = -99;
        break;
    }

    return ApiResult.error(message, code: code);
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  void _logRequest(RequestOptions options) {
    assert(() {
      debugPrint('--- API request ---');
      debugPrint('${options.method} ${options.path}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('params: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('data: ${options.data}');
      }
      return true;
    }());
  }

  void _logResponse(Response<dynamic> response) {
    assert(() {
      debugPrint('--- API response ---');
      debugPrint('${response.statusCode} ${response.requestOptions.path}');
      debugPrint('data: ${response.data}');
      return true;
    }());
  }

  void _logError(DioException error) {
    assert(() {
      debugPrint('--- API error ---');
      debugPrint('${error.type} ${error.requestOptions.path}');
      debugPrint('message: ${error.message}');
      if (error.error != null) {
        debugPrint('cause: ${error.error}');
      }
      if (error.response != null) {
        debugPrint('status: ${error.response?.statusCode}');
        debugPrint('data: ${error.response?.data}');
      }
      return true;
    }());
  }
}
