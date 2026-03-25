library;

import 'package:flutter/foundation.dart';

import 'local_debug_config.dart';

class ApiConfig {
  static String get baseUrl {
    final override = LocalDebugConfig.instance.getString('API_BASE_URL');
    if (override != null && override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) return '';
    if (!isProduction && kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000';
      }
      return 'http://127.0.0.1:8000';
    }
    return productionUrl;
  }

  static const String productionUrl = 'https://xn--lsws2cdzg.top';

  static const bool isProduction = false;

  static bool _useMockApi = false;

  static bool get useMockApi =>
      LocalDebugConfig.instance.getBool('USE_MOCK_API') ?? _useMockApi;

  static set useMockApi(bool value) {
    _useMockApi = value;
  }

  static String get apiUrl => baseUrl;

  static const String ossEndpoint = 'oss-cn-hangzhou.aliyuncs.com';
  static const String ossBucket = 'huiyuanyuan-images';
  static const String ossRegion = 'cn-hangzhou';

  static String get ossBaseUrl => 'https://$ossBucket.$ossEndpoint';

  static String get ossStsUrl => '$apiUrl/api/oss/sts-token';

  static const String dashScopeBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String dashScopeModel = 'qwen-plus';

  static const String fcmProjectId = 'huiyuanyuan-app';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  static const int uploadTimeout = 120000;

  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String authRefresh = '/api/auth/refresh';
  static const String authSendSms = '/api/auth/send-sms';
  static const String authVerifySms = '/api/auth/verify-sms';

  static const String products = '/api/products';
  static String productDetail(String id) => '/api/products/$id';

  static const String shops = '/api/shops';
  static String shopDetail(String id) => '/api/shops/$id';

  static const String orders = '/api/orders';
  static String orderDetail(String id) => '/api/orders/$id';
  static String orderPay(String id) => '${orderDetail(id)}/pay';
  static String orderPayStatus(String id) => '${orderDetail(id)}/pay-status';
  static const String checkout = '/api/orders/checkout';

  static const String userProfile = '/api/users/profile';
  static const String userAddresses = '/api/users/addresses';
  static String userAddressDetail(String id) => '/api/users/addresses/$id';

  static const String paymentAccounts = '/api/users/payment-accounts';
  static String paymentAccountDetail(String id) =>
      '/api/users/payment-accounts/$id';

  static const String reviews = '/api/reviews';
  static String productReviews(String productId) =>
      '/api/products/$productId/reviews';

  static const String favorites = '/api/favorites';
  static String favoriteToggle(String productId) => '/api/favorites/$productId';

  static const String cart = '/api/cart';
  static String cartItem(String productId) => '/api/cart/$productId';

  static const String inventory = '/api/inventory';
  static String inventoryItem(String productId) => '/api/inventory/$productId';
  static String inventoryStock(String productId) =>
      '/api/inventory/$productId/stock';
  static const String inventoryTransactions = '/api/inventory/transactions';

  static const String upload = '/api/upload';
  static const String uploadImage = '/api/upload/image';

  static const String registerDevice = '/api/notifications/register';
  static const String notifications = '/api/notifications';

  static const String health = '/api/health';

  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminStats = adminDashboard;
  static const String adminRestockSuggestions =
      '/api/admin/dashboard/restock-suggestions';
  static const String adminActivities = '/api/admin/activities';
  static const String adminOperators = '/api/admin/operators';
  static String adminOperatorReport(int operatorId) =>
      '/api/admin/operators/$operatorId/report';
  static const String adminOperatorReports = '/api/admin/operators/reports';
  static const String adminSystemStatus = '/api/admin/system/status';
}

class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String acceptLanguage = 'Accept-Language';

  static const String jsonContent = 'application/json';
  static const String multipartContent = 'multipart/form-data';

  static Map<String, String> withAuth(String token) {
    return {
      contentType: jsonContent,
      authorization: 'Bearer $token',
      acceptLanguage: 'zh-CN',
    };
  }

  static Map<String, String> get basic {
    return {
      contentType: jsonContent,
      acceptLanguage: 'zh-CN',
    };
  }
}
