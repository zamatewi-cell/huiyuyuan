library;

import 'dart:async';
import 'dart:io'
    show
        HandshakeException,
        HttpClient,
        HttpHeaders,
        SocketException,
        X509Certificate;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import 'storage_service.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

const List<String> _connectionFailureErrorTerms = [
  'socketexception',
  'failed host lookup',
  'connection refused',
  'connection reset by peer',
  'connection terminated during handshake',
  'handshakeexception',
  'network is unreachable',
  'timed out',
];

const String _productionIpFallbackAttemptedKey =
    'production_ip_fallback_attempted';
const List<int> _productionIpFallbackCertSha1 = <int>[
  216,
  50,
  75,
  115,
  143,
  37,
  74,
  66,
  204,
  19,
  190,
  107,
  75,
  92,
  134,
  144,
  12,
  227,
  10,
  33,
];
const String _productionIpFallbackCertSubject = '/CN=xn--lsws2cdzg.top';
const String _productionIpFallbackCertIssuer = '/C=US/O=Let\'s Encrypt/CN=R13';

const List<String> _forbiddenDetailTermsZh = [
  '没有权限',
  '无权限',
];

const List<String> _notFoundDetailTermsZh = [
  '不存在',
];

const List<String> _serverErrorDetailTermsZh = [
  '服务器错误',
  '内部错误',
];

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
  ApiService.forTesting({
    bool initialized = true,
    Dio? dio,
  })  : _dio = initialized ? (dio ?? Dio()) : dio,
        _initialized = initialized,
        _token = null,
        _refreshRetryCount = 0;

  Dio? _dio;
  bool _initialized = false;
  Future<void>? _initializingFuture;
  String? _token;
  int _refreshRetryCount = 0;

  static const int _maxRefreshRetries = 2;

  final StorageService _storage = StorageService();

  // 临时测试模式：禁用SSL证书验证（仅用于DNS故障时的IP直连测试）
  static const bool _allowSelfSignedCert = bool.fromEnvironment(
    'ALLOW_SELF_SIGNED_CERT',
    defaultValue: false,
  );

  Dio get _client => _dio!;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
        headers: ApiHeaders.basic,
      ),
    );

    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = _createPinnedHttpClient;
    }

    // 添加详细日志拦截器（用于调试网络连接问题）
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[API_LOG] $obj'),
    ));

    if (_allowSelfSignedCert) {
      debugPrint(
        'WARNING: Self-signed certificate validation DISABLED (TEST MODE ONLY)',
      );
    }

    return dio;
  }

  static HttpClient _createPinnedHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (
      X509Certificate cert,
      String host,
      int port,
    ) {
      if (_allowSelfSignedCert) {
        return true;
      }
      return trustsProductionIpFallbackCertificate(cert, host, port);
    };
    return client;
  }

  Future<void> initialize() async {
    if (_initialized && _dio != null) {
      _client.options.baseUrl = ApiConfig.apiUrl;
      return;
    }

    final pendingInitialization = _initializingFuture;
    if (pendingInitialization != null) {
      await pendingInitialization;
      if (_initialized && _dio != null) {
        _client.options.baseUrl = ApiConfig.apiUrl;
      }
      return;
    }

    final completer = Completer<void>();
    _initializingFuture = completer.future;
    try {
      final dio = _buildDio();
      dio.interceptors.add(_createInterceptor());
      _dio = dio;
      await _loadToken();
      _initialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _initializingFuture = null;
    }
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
        if (shouldUseProductionIpFallbackFor(error)) {
          try {
            final retryResponse = await _retryWithProductionIp(
              error.requestOptions,
            );
            handler.resolve(retryResponse);
            return;
          } on DioException catch (retryError) {
            _logError(retryError);
            handler.next(retryError);
            return;
          }
        }

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

  @visibleForTesting
  static bool shouldUseProductionIpFallbackFor(DioException error) {
    if (kIsWeb) {
      return false;
    }

    final requestOptions = error.requestOptions;
    if (requestOptions.extra[_productionIpFallbackAttemptedKey] == true) {
      return false;
    }

    final requestUri = requestOptions.uri;
    if (requestUri.scheme != 'https' ||
        requestUri.host != ApiConfig.productionHost) {
      return false;
    }

    return _isRecoverableConnectionError(error);
  }

  @visibleForTesting
  static bool trustsProductionIpFallbackCertificate(
    X509Certificate cert,
    String host,
    int port,
  ) {
    if (host != ApiConfig.productionIpAddress || port != 443) {
      return false;
    }

    if (!_matchesCertificateFingerprint(cert.sha1, _productionIpFallbackCertSha1)) {
      return false;
    }

    if (cert.subject != _productionIpFallbackCertSubject ||
        cert.issuer != _productionIpFallbackCertIssuer) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final start = cert.startValidity.toUtc();
    final end = cert.endValidity.toUtc();
    return !now.isBefore(start) && !now.isAfter(end);
  }

  static bool _isRecoverableConnectionError(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return true;
    }

    final rawError = error.error;
    if (rawError is SocketException || rawError is HandshakeException) {
      return true;
    }

    if (error.type != DioExceptionType.unknown) {
      return false;
    }

    final normalized = rawError?.toString().trim().toLowerCase();
    return normalized != null &&
        normalized.isNotEmpty &&
        _containsAny(normalized, _connectionFailureErrorTerms);
  }

  static bool _matchesCertificateFingerprint(
    List<int> actual,
    List<int> expected,
  ) {
    if (actual.length != expected.length) {
      return false;
    }

    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  Future<Response<dynamic>> _retryWithProductionIp(
    RequestOptions requestOptions,
  ) {
    final fallbackUri = requestOptions.uri.replace(
      host: ApiConfig.productionIpAddress,
    );
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers[HttpHeaders.hostHeader] = ApiConfig.productionHost;
    if (_token != null && !headers.containsKey(ApiHeaders.authorization)) {
      headers[ApiHeaders.authorization] = 'Bearer $_token';
    }

    debugPrint(
      '[API_RETRY] Falling back to ${fallbackUri.origin} for '
      '${requestOptions.method} ${requestOptions.uri}',
    );

    return _client.fetch<dynamic>(
      requestOptions.copyWith(
        path: fallbackUri.toString(),
        baseUrl: '',
        queryParameters: const <String, dynamic>{},
        headers: headers,
        extra: {
          ...requestOptions.extra,
          _productionIpFallbackAttemptedKey: true,
        },
      ),
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

    return _client.request<dynamic>(
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

      final response = await _client.post(
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

  Future<void> clearAuth() async {
    await _clearToken();
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
    if (ApiConfig.useMockApi) {
      return ApiResult.error('api_mock_mode'.tr, code: -1);
    }
    await _ensureInitialized();

    try {
      final response = await _client.get(path, queryParameters: params);
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
    if (ApiConfig.useMockApi) {
      return ApiResult.error('api_mock_mode'.tr, code: -1);
    }
    await _ensureInitialized();

    try {
      final response = await _client.post(
        path,
        data: data,
        queryParameters: params,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (error) {
      return _handleError(error);
    }
  }

  Future<Response<dynamic>> postRaw(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    if (ApiConfig.useMockApi) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.cancel,
        error: 'api_mock_mode'.tr,
      );
    }
    await _ensureInitialized();

    return _client.post<dynamic>(
      path,
      data: data,
      queryParameters: params,
      options: options,
    );
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (ApiConfig.useMockApi) {
      return ApiResult.error('api_mock_mode'.tr, code: -1);
    }
    await _ensureInitialized();

    try {
      final response = await _client.put(
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
    if (ApiConfig.useMockApi) {
      return ApiResult.error('api_mock_mode'.tr, code: -1);
    }
    await _ensureInitialized();

    try {
      final response = await _client.delete(
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

      final response = await _client.post(
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

      final response = await _client.post(
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

  Future<ApiResult<Uint8List>> downloadBytes(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    if (ApiConfig.useMockApi) {
      return ApiResult.error('api_mock_mode'.tr, code: -1);
    }
    await _ensureInitialized();

    try {
      final response = await _client.get<dynamic>(
        path,
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        return ApiResult.error(
          'api_error_request_failed'.tr,
          code: response.statusCode,
        );
      }

      final bytes = _asUint8List(response.data);
      if (bytes == null || bytes.isEmpty) {
        return ApiResult.error('api_error_parse_failed'.tr);
      }

      return ApiResult.success(bytes);
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
          return ApiResult.error(
            'api_error_parse_failed'.trArgs({
              'error': error,
            }),
          );
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
          ? 'api_error_request_failed'.tr
          : jsonAsString(
              responseMap['message'],
              fallback: 'api_error_request_failed'.tr,
            ),
      code: response.statusCode,
    );
  }

  Uint8List? _asUint8List(dynamic data) {
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    if (data is List) {
      final bytes = <int>[];
      for (final value in data) {
        if (value is int) {
          bytes.add(value);
          continue;
        }
        if (value is num) {
          bytes.add(value.toInt());
          continue;
        }
        return null;
      }
      return Uint8List.fromList(bytes);
    }
    return null;
  }

  ApiResult<T> _handleError<T>(DioException error) {
    // 添加详细的错误日志用于调试
    debugPrint('[API_ERROR] Type: ${error.type}');
    debugPrint('[API_ERROR] Message: ${error.message}');
    debugPrint('[API_ERROR] Error: ${error.error}');
    debugPrint('[API_ERROR] Response Status: ${error.response?.statusCode}');
    debugPrint('[API_ERROR] Request URL: ${error.requestOptions.uri}');
    
    String message;
    int code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'api_error_connect_timeout'.tr;
        code = -1;
        break;
      case DioExceptionType.sendTimeout:
        message = 'api_error_send_timeout'.tr;
        code = -2;
        break;
      case DioExceptionType.receiveTimeout:
        message = 'api_error_receive_timeout'.tr;
        code = -3;
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        code = statusCode;
        final responseData = error.response?.data;
        final detailMessage = responseData is Map
            ? (responseData['detail'] ?? responseData['message'])?.toString()
            : null;
        final localizedDetailMessage = _localizeHttpErrorMessage(
          detailMessage,
          statusCode: statusCode,
        );
        if (statusCode == 401) {
          message = localizedDetailMessage ?? 'error_session_expired'.tr;
        } else if (statusCode == 403) {
          message = localizedDetailMessage ?? 'api_error_forbidden'.tr;
        } else if (statusCode == 404) {
          message = localizedDetailMessage ?? 'api_error_not_found'.tr;
        } else if (statusCode >= 500) {
          message = localizedDetailMessage ?? 'api_error_server_failed'.tr;
        } else {
          message = localizedDetailMessage ?? 'api_error_request_failed'.tr;
        }
        break;
      case DioExceptionType.cancel:
        message = 'api_error_cancelled'.tr;
        code = -4;
        break;
      case DioExceptionType.connectionError:
        message = 'api_error_connection_failed'.tr;
        code = -5;
        break;
      case DioExceptionType.unknown:
        final rawError = error.error?.toString().trim();
        if (rawError != null && rawError.isNotEmpty) {
          final normalized = rawError.toLowerCase();
          if (_containsAny(normalized, _connectionFailureErrorTerms)) {
            message = 'api_error_connection_failed'.tr;
            code = -5;
            break;
          }
          message = 'api_error_request_exception_with_detail'.trArgs({
            'error': rawError,
          });
        } else {
          message = 'api_error_request_exception'.tr;
        }
        code = -99;
        break;
      default:
        final fallbackMessage = error.message?.trim();
        if (fallbackMessage == null || fallbackMessage.isEmpty) {
          message = 'api_error_network_generic'.tr;
        } else {
          message = 'api_error_network_with_detail'.trArgs({
            'error': fallbackMessage,
          });
        }
        code = -99;
        break;
    }

    return ApiResult.error(message, code: code);
  }

  String? _localizeHttpErrorMessage(
    String? detailMessage, {
    required int statusCode,
  }) {
    final text = detailMessage?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final normalized = text.toLowerCase();

    if (statusCode == 401) {
      return 'error_session_expired'.tr;
    }

    if (statusCode == 403 &&
        (_containsAny(text, _forbiddenDetailTermsZh) ||
            normalized.contains('permission'))) {
      return 'api_error_forbidden'.tr;
    }

    if (statusCode == 404 &&
        (_containsAny(text, _notFoundDetailTermsZh) ||
            normalized.contains('not found'))) {
      return 'api_error_not_found'.tr;
    }

    if (statusCode >= 500 &&
        (_containsAny(text, _serverErrorDetailTermsZh) ||
            normalized.contains('internal server error'))) {
      return 'api_error_server_failed'.tr;
    }

    return text;
  }

  static bool _containsAny(String text, Iterable<String> terms) {
    return terms.any(text.contains);
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized || _dio == null) {
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
