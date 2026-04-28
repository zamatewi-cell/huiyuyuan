library;

import 'package:flutter/foundation.dart';

import 'local_debug_config.dart';

class ApiConfig {
  static const String _injectedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _injectedUseMockApi = String.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_injectedBaseUrl.isNotEmpty) {
      return _injectedBaseUrl;
    }
    final override = LocalDebugConfig.instance.getString('API_BASE_URL');
    if (override != null && override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) return '';
    return productionUrl;
  }

  static const String productionHost = 'xn--lsws2cdzg.top';
  static const String productionIpAddress = '47.112.98.191';

  // 默认走域名，原生 App 仅在 TLS 握手异常时回退到固定生产 IP。
  static const String productionUrl = 'https://$productionHost';
  static const String productionIpFallbackUrl = 'https://$productionIpAddress';

  static const bool isProduction = false;

  static bool _useMockApi = false;

  static bool get useMockApi {
    final normalizedInjected = _injectedUseMockApi.trim().toLowerCase();
    if (normalizedInjected.isNotEmpty) {
      return normalizedInjected == 'true' ||
          normalizedInjected == '1' ||
          normalizedInjected == 'yes' ||
          normalizedInjected == 'on';
    }
    return LocalDebugConfig.instance.getBool('USE_MOCK_API') ?? _useMockApi;
  }

  static set useMockApi(bool value) {
    _useMockApi = value;
  }

  static String get apiUrl => baseUrl;

  static const String ossEndpoint = 'oss-cn-hangzhou.aliyuncs.com';
  static const String ossBucket = 'huiyuyuan-images';
  static const String ossRegion = 'cn-hangzhou';

  static String get ossBaseUrl => 'https://$ossBucket.$ossEndpoint';

  static String get ossStsUrl => '$apiUrl/api/oss/sts-token';

  static const String dashScopeBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String dashScopeModel = 'qwen-plus';

  static const String fcmProjectId = 'huiyuyuan-app';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  static const int uploadTimeout = 120000;

  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String authRefresh = '/api/auth/refresh';
  static const String authSendSms = '/api/auth/send-sms';
  static const String authVerifySms = '/api/auth/verify-sms';
  static const String authRegister = '/api/auth/register';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authCaptcha = '/api/auth/captcha';
  static const String authDevices = '/api/auth/devices';
  static const String appVersionInfo = '/api/app/version';

  static const String products = '/api/products';
  static String productDetail(String id) => '/api/products/$id';

  static const String shops = '/api/shops';
  static String shopDetail(String id) => '/api/shops/$id';

  static const String orders = '/api/orders';
  static String orderDetail(String id) => '/api/orders/$id';
  static String orderPay(String id) => '${orderDetail(id)}/pay';
  static String orderPayStatus(String id) => '${orderDetail(id)}/pay-status';
  static String paymentCancel(String id) => '/api/payments/$id/cancel';
  static const String checkout = '/api/orders/checkout';

  static const String userProfile = '/api/users/profile';
  static const String userChangePassword = '/api/users/account/change-password';
  static const String userDeactivate = '/api/users/account/deactivate';
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
  static const String aiHealth = '/api/ai/health';
  static const String aiChat = '/api/ai/chat';
  static const String aiAnalyzeImage = '/api/ai/analyze-image';

  static const String registerDevice = '/api/notifications/register';
  static const String notifications = '/api/notifications';

  static const String health = '/api/health';

  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminStats = adminDashboard;
  static const String adminRestockSuggestions =
      '/api/admin/dashboard/restock-suggestions';
  static const String adminActivities = '/api/admin/activities';
  static String adminConfirmPayment(String orderId) =>
      '/api/admin/orders/$orderId/confirm-payment';
  static String adminShipOrder(String orderId) =>
      '/api/admin/orders/$orderId/ship';
  static const String adminPaymentReconciliation =
      '/api/payments/admin/reconciliation';
  static String adminConfirmPaymentRecord(String paymentId) =>
      '/api/payments/admin/$paymentId/confirm';
  static String adminDisputePayment(String paymentId) =>
      '/api/payments/admin/$paymentId/dispute';
  static const String adminOperators = '/api/admin/operators';
  static String adminOperator(String id) => '/api/admin/operators/$id';
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
