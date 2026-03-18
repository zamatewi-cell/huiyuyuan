/// 汇玉源 - API配置文件
///
/// 包含所有后端API的配置信息
library;

import 'package:flutter/foundation.dart';

/// API配置类
class ApiConfig {
  // ============ 服务器配置 ============

  /// 后端API基础URL
  /// 注意：真机测试时需要改为实际服务器地址
  /// - Android模拟器使用: http://10.0.2.2:8000
  /// - iOS模拟器使用: http://localhost:8000
  /// - 真机使用: http://[服务器IP]:8000
  /// - Web环境使用: http://127.0.0.1:8000
  static String get baseUrl {
    // Web 环境使用相对路径（同源请求，经 Nginx 代理到后端）
    if (kIsWeb) return '';
    // 云服务器地址（通过 Nginx 代理，端口80）
    return 'http://47.112.98.191';
  }

  /// 生产环境API URL（配置域名 + HTTPS 后启用）
  static const String productionUrl = 'https://api.huiyuanyuan.com';

  /// 当前是否为生产环境
  static const bool isProduction = false;

  /// 是否使用本地Mock数据 (在对接真实后端前保持为true)
  /// 非 const 以便测试时可动态切换
  static bool useMockApi = false;

  /// 获取当前使用的API URL
  static String get apiUrl => isProduction ? productionUrl : baseUrl;

  // ============ OSS配置 ============

  /// 阿里云OSS配置
  static const String ossEndpoint = 'oss-cn-hangzhou.aliyuncs.com';
  static const String ossBucket = 'huiyuanyuan-images';
  static const String ossRegion = 'cn-hangzhou';

  /// OSS访问域名
  static String get ossBaseUrl => 'https://$ossBucket.$ossEndpoint';

  /// 获取STS临时凭证的API端点
  static String get ossStsUrl => '$apiUrl/api/oss/sts-token';

  // ============ AI服务配置 ============

  /// OpenRouter API配置
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterModel = 'nvidia/nemotron-nano-12b-v2-vl:free';

  // ============ 推送服务配置 ============

  /// Firebase Cloud Messaging
  static const String fcmProjectId = 'huiyuanyuan-app';

  // ============ 超时配置 ============

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 30000;

  /// 发送超时时间（毫秒）
  static const int sendTimeout = 30000;

  /// 上传超时时间（毫秒）
  static const int uploadTimeout = 120000;

  // ============ API路径 ============

  /// 认证相关
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String authRefresh = '/api/auth/refresh';

  /// 短信验证码（真实后端部署后使用）
  static const String authSendSms = '/api/auth/send-sms';
  static const String authVerifySms = '/api/auth/verify-sms';

  /// 商品相关
  static const String products = '/api/products';
  static String productDetail(String id) => '/api/products/$id';

  /// 店铺相关
  static const String shops = '/api/shops';
  static String shopDetail(String id) => '/api/shops/$id';

  /// 订单相关
  static const String orders = '/api/orders';
  static String orderDetail(String id) => '/api/orders/$id';
  static const String checkout = '/api/orders/checkout';

  /// 用户相关
  static const String userProfile = '/api/users/profile';
  static const String userAddresses = '/api/users/addresses';
  static String userAddressDetail(String id) => '/api/users/addresses/$id';

  /// 支付账户相关
  static const String paymentAccounts = '/api/users/payment-accounts';
  static String paymentAccountDetail(String id) => '/api/users/payment-accounts/$id';

  /// 评价相关
  static const String reviews = '/api/reviews';
  static String productReviews(String productId) =>
      '/api/products/$productId/reviews';

  /// 收藏相关
  static const String favorites = '/api/favorites';
  static String favoriteToggle(String productId) => '/api/favorites/$productId';

  /// 购物车相关
  static const String cart = '/api/cart';
  static String cartItem(String productId) => '/api/cart/$productId';

  /// 库存相关
  static const String inventory = '/api/inventory';
  static String inventoryItem(String productId) => '/api/inventory/$productId';
  static String inventoryStock(String productId) =>
      '/api/inventory/$productId/stock';
  static const String inventoryTransactions = '/api/inventory/transactions';

  /// 文件上传
  static const String upload = '/api/upload';
  static const String uploadImage = '/api/upload/image';

  /// 推送通知
  static const String registerDevice = '/api/notifications/register';
  static const String notifications = '/api/notifications';

  /// 健康检查
  static const String health = '/api/health';

  /// 管理员相关
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminStats = '/api/admin/dashboard/stats';
  static const String adminRestockSuggestions = '/api/admin/dashboard/restock-suggestions';
  static const String adminActivities = '/api/admin/dashboard/activities';
  static const String adminOperators = '/api/admin/operators';
  static String adminOperatorReport(int operatorId) => '/api/admin/operators/$operatorId/report';
  static const String adminOperatorReports = '/api/admin/operators/reports';
  static const String adminSystemStatus = '/api/admin/system/status';
}

/// 请求头配置
class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String acceptLanguage = 'Accept-Language';

  static const String jsonContent = 'application/json';
  static const String multipartContent = 'multipart/form-data';

  /// 获取带认证的请求头
  static Map<String, String> withAuth(String token) {
    return {
      contentType: jsonContent,
      authorization: 'Bearer $token',
      acceptLanguage: 'zh-CN',
    };
  }

  /// 获取基础请求头
  static Map<String, String> get basic {
    return {
      contentType: jsonContent,
      acceptLanguage: 'zh-CN',
    };
  }
}
