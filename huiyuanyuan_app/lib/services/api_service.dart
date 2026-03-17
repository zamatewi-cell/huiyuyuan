/// 汇玉源 - 统一API服务
///
/// 功能:
/// - HTTP请求封装
/// - Token自动刷新
/// - 错误统一处理
/// - 请求/响应拦截
/// - 离线缓存支持
library;

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// API响应结果封装
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

/// 统一API服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  bool _initialized = false;
  String? _token;
  int _refreshRetryCount = 0;
  static const int _maxRefreshRetries = 2;

  final StorageService _storage = StorageService();

  /// 初始化（每次调用确保 baseUrl 与当前平台匹配）
  Future<void> initialize() async {
    // 不缓存，每次都用最新的 apiUrl 重建 Dio（Web / Native baseUrl 不同）
    if (_initialized) {
      // 更新 baseUrl 确保 Web 环境正确
      _dio.options.baseUrl = ApiConfig.apiUrl;
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
      headers: ApiHeaders.basic,
    ));

    // 添加拦截器
    _dio.interceptors.add(_createInterceptor());

    // 尝试从本地加载Token
    await _loadToken();

    _initialized = true;
  }

  /// 创建请求拦截器
  Interceptor _createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加认证头
        if (_token != null) {
          options.headers[ApiHeaders.authorization] = 'Bearer $_token';
        }

        // 日志输出
        _logRequest(options);

        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) async {
        // 处理401错误（Token过期）—— 限制重试次数防止无限循环
        if (error.response?.statusCode == 401 && _refreshRetryCount < _maxRefreshRetries) {
          _refreshRetryCount++;
          final refreshed = await _refreshToken();
          if (refreshed) {
            // 重试原请求
            try {
              final retryResponse = await _retry(error.requestOptions);
              _refreshRetryCount = 0; // 成功后重置计数
              handler.resolve(retryResponse);
              return;
            } catch (_) {
              // 重试失败
            }
          }
          // Token刷新失败，需要重新登录
          await _clearToken();
        } else if (error.response?.statusCode == 401) {
          // 超过最大重试次数，直接清除 Token
          _refreshRetryCount = 0;
          await _clearToken();
        }

        _logError(error);
        handler.next(error);
      },
    );
  }

  /// 重试请求
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
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

  /// 刷新Token
  Future<bool> _refreshToken() async {
    try {
      final response = await _dio.post(
        ApiConfig.authRefresh,
        options: Options(
          headers: {ApiHeaders.authorization: 'Bearer $_token'},
        ),
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        _token = response.data['token'];
        await _saveToken(_token!);
        return true;
      }
    } catch (_) {
      // 刷新失败
    }
    return false;
  }

  // ============ Token管理 ============

  /// 设置Token
  Future<void> setToken(String token) async {
    _token = token;
    await _saveToken(token);
  }

  /// 获取当前Token
  String? get token => _token;

  /// 是否已登录
  bool get isLoggedIn => _token != null;

  /// 加载本地Token
  Future<void> _loadToken() async {
    final user = await _storage.getUser();
    _token = user?['token'];
  }

  /// 保存Token到本地
  Future<void> _saveToken(String token) async {
    final user = await _storage.getUser() ?? {};
    user['token'] = token;
    await _storage.saveUser(user);
  }

  /// 清除Token
  Future<void> _clearToken() async {
    _token = null;
    await _storage.clearUser();
  }

  // ============ HTTP方法 ============

  /// GET请求
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final response = await _dio.get(path, queryParameters: params);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST请求
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PUT请求
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE请求
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    await _ensureInitialized();

    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// 上传文件
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
          sendTimeout: Duration(milliseconds: ApiConfig.uploadTimeout),
        ),
        onSendProgress: onProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// 上传字节流（适用于 Web 平台无本地文件路径的场景）
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
          sendTimeout: Duration(milliseconds: ApiConfig.uploadTimeout),
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============ 响应处理 ============

  /// 处理响应
  ApiResult<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      // 如果提供了fromJson，使用它解析数据
      if (fromJson != null) {
        try {
          final parsed = fromJson(data);
          return ApiResult.success(parsed);
        } catch (e) {
          return ApiResult.error('数据解析失败: $e');
        }
      }

      // 否则直接返回原始数据
      // 同时提取 message 字段（后端测试模式验证码等场景需要）
      String? msg;
      if (data is Map) {
        msg = data['message'] as String?;
      }
      return ApiResult.success(data as T, message: msg);
    }

    return ApiResult.error(
      response.data?['message'] ?? '请求失败',
      code: response.statusCode,
    );
  }

  /// 处理错误
  ApiResult<T> _handleError<T>(DioException e) {
    String message;
    int code;

    switch (e.type) {
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
        final statusCode = e.response?.statusCode ?? 500;
        code = statusCode;
        // FastAPI 错误用 'detail'，其他框架用 'message'
        final responseData = e.response?.data;
        final detailMsg = responseData is Map
            ? (responseData['detail'] ?? responseData['message'])?.toString()
            : null;
        if (statusCode == 401) {
          message = detailMsg ?? '登录已过期，请重新登录';
        } else if (statusCode == 403) {
          message = detailMsg ?? '没有权限执行此操作';
        } else if (statusCode == 404) {
          message = detailMsg ?? '请求的资源不存在';
        } else if (statusCode >= 500) {
          message = detailMsg ?? '服务器错误，请稍后重试';
        } else {
          message = detailMsg ?? '请求失败';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        code = -4;
        break;
      case DioExceptionType.connectionError:
        message = '网络连接失败，请检查网络';
        code = -5;
        break;
      default:
        message = '网络错误: ${e.message}';
        code = -99;
    }

    return ApiResult.error(message, code: code);
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ============ 日志 ============

  void _logRequest(RequestOptions options) {
    // 仅在调试模式下输出
    assert(() {
      print('┌─────────────────────────────────────────');
      print('│ [API请求] ${options.method} ${options.path}');
      if (options.queryParameters.isNotEmpty) {
        print('│ 参数: ${options.queryParameters}');
      }
      if (options.data != null) {
        print('│ 数据: ${options.data}');
      }
      print('└─────────────────────────────────────────');
      return true;
    }());
  }

  void _logResponse(Response response) {
    assert(() {
      print('┌─────────────────────────────────────────');
      print('│ [API响应] ${response.statusCode} ${response.requestOptions.path}');
      print('│ 数据: ${response.data}');
      print('└─────────────────────────────────────────');
      return true;
    }());
  }

  void _logError(DioException error) {
    assert(() {
      print('┌─────────────────────────────────────────');
      print('│ [API错误] ${error.type} ${error.requestOptions.path}');
      print('│ 消息: ${error.message}');
      if (error.response != null) {
        print('│ 状态: ${error.response?.statusCode}');
        print('│ 数据: ${error.response?.data}');
      }
      print('└─────────────────────────────────────────');
      return true;
    }());
  }
}
