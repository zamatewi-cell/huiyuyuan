/// 汇玉源 - 支付服务
///
/// 功能:
/// - 微信支付
/// - 支付宝支付
/// - 支付状态查询
/// - 退款申请
///
/// 注意: 正式对接需要配置商户信息
library;

import 'dart:convert';
import 'package:dio/dio.dart';

/// 支付方式枚举
enum PaymentMethod {
  wechat('微信支付', 'wechat'),
  alipay('支付宝', 'alipay'),
  unionpay('银联支付', 'unionpay'),
  balance('余额支付', 'balance');

  final String label;
  final String code;
  const PaymentMethod(this.label, this.code);
}

/// 支付状态枚举
enum PaymentStatus {
  pending('待支付'),
  processing('支付中'),
  success('支付成功'),
  failed('支付失败'),
  cancelled('已取消'),
  refunding('退款中'),
  refunded('已退款');

  final String label;
  const PaymentStatus(this.label);
}

/// 支付订单模型
class PaymentOrder {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId; // 第三方交易号
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? errorMessage;

  PaymentOrder({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.paidAt,
    this.errorMessage,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.code == json['method'],
        orElse: () => PaymentMethod.alipay,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transaction_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'method': method.code,
      'status': status.name,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'error_message': errorMessage,
    };
  }
}

/// 支付服务类
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late final Dio _dio;
  bool _initialized = false;

  // 支付配置 (正式环境需替换为真实配置)
  static const String _paymentApiUrl = 'https://api.huiyuanyuan.com/payment';

  // 微信支付配置
  static const String _wechatAppId = 'wx_your_app_id';
  static const String _wechatMchId = 'your_mch_id';

  // 支付宝配置
  static const String _alipayAppId = 'your_alipay_app_id';

  /// 初始化
  void _ensureInitialized() {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: _paymentApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _initialized = true;
  }

  // ============ 支付功能 ============

  /// 创建支付订单
  Future<PaymentOrder> createPaymentOrder({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? description,
  }) async {
    _ensureInitialized();

    try {
      // 调用后端创建支付订单
      // 正式环境: 发送请求到后端，后端调用微信/支付宝接口
      final response = await _dio.post('/create', data: {
        'order_id': orderId,
        'amount': amount,
        'method': method.code,
        'description': description ?? '汇玉源珠宝商品',
      });

      if (response.statusCode == 200) {
        return PaymentOrder.fromJson(response.data);
      }

      throw Exception('创建支付订单失败');
    } on DioException {
      // 模拟创建订单 (演示模式)
      return _createMockPaymentOrder(orderId, amount, method);
    } catch (e) {
      return _createMockPaymentOrder(orderId, amount, method);
    }
  }

  /// 模拟创建支付订单
  PaymentOrder _createMockPaymentOrder(
    String orderId,
    double amount,
    PaymentMethod method,
  ) {
    return PaymentOrder(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// 发起微信支付
  Future<Map<String, dynamic>> initiateWechatPay(PaymentOrder order) async {
    _ensureInitialized();

    // 正式环境: 调用微信支付SDK
    // 这里返回模拟的支付参数
    return {
      'appId': _wechatAppId,
      'partnerId': _wechatMchId,
      'prepayId': 'wx${DateTime.now().millisecondsSinceEpoch}',
      'package': 'Sign=WXPay',
      'nonceStr': _generateNonceStr(),
      'timeStamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'sign': 'MOCK_SIGN_${order.id}',
    };
  }

  /// 发起支付宝支付
  Future<String> initiateAlipay(PaymentOrder order) async {
    _ensureInitialized();

    // 正式环境: 调用支付宝SDK
    // 这里返回模拟的支付字符串
    final params = {
      'app_id': _alipayAppId,
      'method': 'alipay.trade.app.pay',
      'charset': 'utf-8',
      'sign_type': 'RSA2',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'biz_content': jsonEncode({
        'out_trade_no': order.orderId,
        'total_amount': order.amount.toStringAsFixed(2),
        'subject': '汇玉源珠宝商品',
        'product_code': 'QUICK_MSECURITY_PAY',
      }),
    };

    // 模拟返回支付字符串
    return 'alipay_sdk=alipay-sdk-flutter&${Uri(queryParameters: params).query}';
  }

  /// 查询支付状态
  Future<PaymentStatus> queryPaymentStatus(String paymentId) async {
    _ensureInitialized();

    try {
      final response = await _dio.get('/status/$paymentId');

      if (response.statusCode == 200) {
        final status = response.data['status'] as String?;
        return PaymentStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => PaymentStatus.pending,
        );
      }

      return PaymentStatus.pending;
    } catch (e) {
      // 模拟查询结果
      return PaymentStatus.pending;
    }
  }

  /// 模拟支付成功 (仅用于演示)
  Future<PaymentOrder> simulatePaymentSuccess(PaymentOrder order) async {
    // 模拟支付成功
    await Future.delayed(const Duration(seconds: 2));

    return PaymentOrder(
      id: order.id,
      orderId: order.orderId,
      amount: order.amount,
      method: order.method,
      status: PaymentStatus.success,
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: order.createdAt,
      paidAt: DateTime.now(),
    );
  }

  /// 取消支付
  Future<bool> cancelPayment(String paymentId) async {
    _ensureInitialized();

    try {
      final response = await _dio.post('/cancel/$paymentId');
      return response.statusCode == 200;
    } catch (e) {
      return true; // 模拟取消成功
    }
  }

  // ============ 退款功能 ============

  /// 申请退款
  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio.post('/refund', data: {
        'order_id': orderId,
        'payment_id': paymentId,
        'amount': amount,
        'reason': reason ?? '用户申请退款',
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'refund_id': response.data['refund_id'],
          'message': '退款申请已提交',
        };
      }

      throw Exception('退款申请失败');
    } catch (e) {
      // 模拟退款成功
      return {
        'success': true,
        'refund_id': 'REFUND-${DateTime.now().millisecondsSinceEpoch}',
        'message': '退款申请已提交，预计1-3个工作日到账',
      };
    }
  }

  /// 查询退款状态
  Future<Map<String, dynamic>> queryRefundStatus(String refundId) async {
    _ensureInitialized();

    try {
      final response = await _dio.get('/refund/$refundId');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('查询失败');
    } catch (e) {
      // 模拟查询结果
      return {
        'refund_id': refundId,
        'status': 'processing',
        'message': '退款处理中',
      };
    }
  }

  // ============ 辅助方法 ============

  /// 生成随机字符串
  String _generateNonceStr() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(chars[DateTime.now().microsecond % chars.length]);
    }
    return buffer.toString();
  }

  /// 获取支付方式图标
  static String getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wechat:
        return '💚'; // 实际应用中使用图片资源
      case PaymentMethod.alipay:
        return '💙';
      case PaymentMethod.unionpay:
        return '❤️';
      case PaymentMethod.balance:
        return '💰';
    }
  }

  /// 格式化金额
  static String formatAmount(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }
}

/// 支付结果回调
typedef PaymentCallback = void Function(bool success, String? message);

/// 支付配置信息
class PaymentConfig {
  /// 微信支付商户号
  static const String wechatMchId = 'YOUR_MCH_ID';

  /// 微信支付AppID
  static const String wechatAppId = 'YOUR_WECHAT_APP_ID';

  /// 支付宝AppID
  static const String alipayAppId = 'YOUR_ALIPAY_APP_ID';

  /// 支付回调地址
  static const String notifyUrl = 'https://api.huiyuanyuan.com/payment/notify';

  /// 是否为沙箱环境
  static const bool isSandbox = true;
}
