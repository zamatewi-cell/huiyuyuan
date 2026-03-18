/// 汇玉源 - 后端服务
///
/// 功能:
/// - API请求封装
/// - 产品/店铺数据获取
/// - 错误处理
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

/// 后端服务类
class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  late final Dio _dio;
  bool _initialized = false;

  /// 使用 ApiConfig 统一配置的 baseUrl
  static String get baseUrl => ApiConfig.baseUrl;

  /// 初始化
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

    // 自动注入 Auth Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // 无 token 时继续匿名请求
        }
        handler.next(options);
      },
    ));

    _initialized = true;
  }

  /// 获取产品列表
  Future<List<ProductModel>> getProducts({String? category}) async {
    initialize();
    try {
      final response = await _dio.get('/api/products', queryParameters: {
        if (category != null && category != '全部') 'category': category,
      });

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((item) => ProductModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      // Keep the service API-only. Callers decide how to handle empty results.
      return [];
    }
  }

  /// 获取产品详情
  Future<ProductModel?> getProductDetail(String productId) async {
    initialize();
    try {
      final response = await _dio.get('/api/products/$productId');

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET请求
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    initialize();
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST请求
  Future<dynamic> post(String path, {dynamic data}) async {
    initialize();
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 错误处理
  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('连接超时，请检查网络');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('响应超时，请稍后重试');
    } else if (e.response != null) {
      return Exception('服务器错误: ${e.response?.statusCode}');
    } else {
      return Exception('网络错误: ${e.message}');
    }
  }

  /// 检查服务器连接
  Future<bool> checkConnection() async {
    try {
      await get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}
