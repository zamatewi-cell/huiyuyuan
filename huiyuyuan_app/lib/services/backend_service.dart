/// HuiYuYuan backend service.
///
/// Responsibilities:
/// - Wrap API requests
/// - Fetch product and shop data
/// - Normalize network errors
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_strings.dart';
import '../l10n/translator_global.dart';
import '../models/user_model.dart';
import '../models/json_parsing.dart';
import '../config/api_config.dart';
import '../providers/app_settings_provider.dart';

/// Shared backend client.
class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  late final Dio _dio;
  bool _initialized = false;

  /// Uses the centralized base URL from [ApiConfig].
  static String get baseUrl => ApiConfig.baseUrl;

  /// Initializes the Dio client once.
  void initialize() {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Inject the auth token automatically when it is available.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Continue anonymously when no token is available.
        }
        handler.next(options);
      },
    ));

    _initialized = true;
  }

  /// Fetches the product list.
  Future<List<ProductModel>> getProducts({String? category}) async {
    initialize();
    try {
      final response = await _dio.get('/api/products', queryParameters: {
        if (category != null && !_isAllCategory(category)) 'category': category,
      });

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((item) => ProductModel.fromJson(jsonAsMap(item)))
            .toList();
      }
      return [];
    } catch (e) {
      // Keep the service API-only. Callers decide how to handle empty results.
      return [];
    }
  }

  /// Fetches a single product by id.
  Future<ProductModel?> getProductDetail(String productId) async {
    initialize();
    try {
      final response = await _dio.get('/api/products/$productId');

      if (response.statusCode == 200) {
        return ProductModel.fromJson(jsonAsMap(response.data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Performs a GET request.
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    initialize();
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a POST request.
  Future<dynamic> post(String path, {dynamic data}) async {
    initialize();
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Maps Dio failures to user-facing exceptions.
  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception(_t('api_error_connect_timeout'));
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception(_t('api_error_receive_timeout'));
    } else if (e.response != null) {
      return Exception(_t('api_error_server_status', params: {
        'status': e.response?.statusCode ?? '-',
      }));
    } else {
      final message = e.message?.trim();
      if (message == null || message.isEmpty) {
        return Exception(_t('api_error_network_generic'));
      }
      return Exception(_t('api_error_network_with_detail', params: {
        'error': message,
      }));
    }
  }

  /// Checks whether the server is reachable.
  Future<bool> checkConnection() async {
    try {
      await get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}

String _t(String key, {Map<String, Object?> params = const {}}) {
  return TranslatorGlobal.instance.translate(key, params: params);
}

bool _isAllCategory(String? category) {
  final value = category?.trim();
  if (value == null || value.isEmpty) {
    return false;
  }
  if (value == 'platform_all') {
    return true;
  }
  return AppLanguage.values.any(
    (language) => AppStrings.get(language, 'platform_all') == value,
  );
}
