library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/payment_models.dart';
import '../services/api_service.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

class PaymentRepository {
  PaymentRepository({Dio? dio, ApiService? apiService})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: PaymentConfig.gatewayUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {'Content-Type': 'application/json'},
              ),
            ),
        _api = apiService ?? ApiService();

  final Dio _dio;
  final ApiService _api;

  Future<PaymentOrder> createPaymentOrder({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/create',
        data: {
          'order_id': orderId,
          'amount': amount,
          'method': method.code,
          'description': description ?? 'payment_order_subject'.tr,
        },
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = _extractMap(response.data);
        if (data != null) {
          return PaymentOrder.fromJson(data);
        }
      }

      throw Exception('payment_create_order_failed'.tr);
    } on DioException catch (error) {
      debugPrint('[PaymentRepository] createPaymentOrder failed: $error');
      return _createMockPaymentOrder(orderId, amount, method);
    } catch (error) {
      debugPrint('[PaymentRepository] createPaymentOrder failed: $error');
      return _createMockPaymentOrder(orderId, amount, method);
    }
  }

  Future<WechatPayParams> initiateWechatPay(PaymentOrder order) async {
    return WechatPayParams(
      appId: PaymentConfig.wechatAppId,
      partnerId: PaymentConfig.wechatMchId,
      prepayId: 'wx${DateTime.now().millisecondsSinceEpoch}',
      packageValue: 'Sign=WXPay',
      nonceStr: _generateNonceStr(),
      timeStamp: (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      sign: 'MOCK_SIGN_${order.id}',
    );
  }

  Future<AlipayPaymentRequest> initiateAlipay(PaymentOrder order) async {
    final params = <String, String>{
      'app_id': PaymentConfig.alipayAppId,
      'method': 'alipay.trade.app.pay',
      'charset': 'utf-8',
      'sign_type': 'RSA2',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'biz_content': jsonEncode({
        'out_trade_no': order.orderId,
        'total_amount': order.amount.toStringAsFixed(2),
        'subject': 'payment_order_subject'.tr,
        'product_code': 'QUICK_MSECURITY_PAY',
      }),
    };

    return AlipayPaymentRequest(
      orderString:
          'alipay_sdk=alipay-sdk-flutter&${Uri(queryParameters: params).query}',
    );
  }

  Future<PaymentStatus> queryPaymentStatus(String paymentId) async {
    try {
      final response = await _dio.get('/status/$paymentId');
      if (_isSuccessStatus(response.statusCode)) {
        final data = _extractMap(response.data);
        if (data != null) {
          return paymentStatusFromValue(
            data['status'],
            fallback: PaymentStatus.pending,
          );
        }
      }
    } catch (error) {
      debugPrint('[PaymentRepository] queryPaymentStatus failed: $error');
    }

    return PaymentStatus.pending;
  }

  Future<OrderPaymentStatusResult?> submitOrderPayment({
    required String orderId,
    required PaymentMethod method,
  }) async {
    try {
      final result = await _api.post<dynamic>(
        ApiConfig.orderPay(orderId),
        data: {'method': method.code},
      );
      if (!result.success) {
        throw Exception(result.message ?? 'payment_create_order_failed'.tr);
      }
      if (result.data == null) {
        throw Exception('payment_create_order_failed'.tr);
      }

      final data = _extractMap(result.data);
      return data == null ? null : OrderPaymentStatusResult.fromJson(data);
    } catch (error) {
      debugPrint('[PaymentRepository] submitOrderPayment failed: $error');
      return null;
    }
  }

  Future<OrderPaymentStatusResult?> queryOrderPaymentStatus(
    String orderId,
  ) async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.orderPayStatus(orderId));
      if (!result.success || result.data == null) {
        return null;
      }

      final data = _extractMap(result.data);
      return data == null ? null : OrderPaymentStatusResult.fromJson(data);
    } catch (error) {
      debugPrint('[PaymentRepository] queryOrderPaymentStatus failed: $error');
      return null;
    }
  }

  Future<bool> cancelPayment(String paymentId) async {
    try {
      final result =
          await _api.post<dynamic>(ApiConfig.paymentCancel(paymentId));
      return result.success;
    } catch (error) {
      debugPrint('[PaymentRepository] cancelPayment failed: $error');
      return false;
    }
  }

  Future<RefundRequestResult> requestRefund({
    required String orderId,
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/refund',
        data: {
          'order_id': orderId,
          'payment_id': paymentId,
          'amount': amount,
          'reason': reason ?? 'payment_refund_reason_customer'.tr,
        },
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = _extractMap(response.data) ?? const <String, dynamic>{};
        return RefundRequestResult(
          success: true,
          refundId: jsonAsString(data['refund_id']),
          message: jsonAsString(
            data['message'],
            fallback: 'payment_refund_submitted'.tr,
          ),
        );
      }

      throw Exception('payment_refund_request_failed'.tr);
    } catch (error) {
      debugPrint('[PaymentRepository] requestRefund failed: $error');
      return RefundRequestResult(
        success: true,
        refundId: 'REFUND-${DateTime.now().millisecondsSinceEpoch}',
        message: 'payment_refund_submitted_eta'.tr,
      );
    }
  }

  Future<RefundStatusResult> queryRefundStatus(String refundId) async {
    try {
      final response = await _dio.get('/refund/$refundId');

      if (_isSuccessStatus(response.statusCode)) {
        final data = _extractMap(response.data);
        if (data != null) {
          return RefundStatusResult.fromJson(data);
        }
      }

      throw Exception('payment_refund_status_query_failed'.tr);
    } catch (error) {
      debugPrint('[PaymentRepository] queryRefundStatus failed: $error');
      return RefundStatusResult(
        refundId: refundId,
        status: RefundStatus.processing,
        message: 'payment_refund_processing'.tr,
      );
    }
  }

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

  bool _isSuccessStatus(int? statusCode) {
    return statusCode == 200 || statusCode == 201;
  }

  Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'] ?? raw['item'] ?? raw['result'];
      if (nested is Map || nested is Map<String, dynamic>) {
        return jsonAsMap(nested);
      }
      return raw;
    }
    if (raw is Map) {
      final map = jsonAsMap(raw);
      final nested = map['data'] ?? map['item'] ?? map['result'];
      if (nested is Map || nested is Map<String, dynamic>) {
        return jsonAsMap(nested);
      }
      return map;
    }
    return null;
  }

  String _generateNonceStr() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var index = 0; index < 32; index++) {
      buffer.write(chars[DateTime.now().microsecond % chars.length]);
    }
    return buffer.toString();
  }
}
