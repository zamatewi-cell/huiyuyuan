library;

export '../models/payment_models.dart';

import '../models/payment_models.dart';
import '../repositories/payment_repository.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() => _instance;

  PaymentService._internal() : _repository = PaymentRepository();

  final PaymentRepository _repository;

  Future<PaymentOrder> createPaymentOrder({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? description,
  }) {
    return _repository.createPaymentOrder(
      orderId: orderId,
      amount: amount,
      method: method,
      description: description,
    );
  }

  Future<WechatPayParams> initiateWechatPay(PaymentOrder order) {
    return _repository.initiateWechatPay(order);
  }

  Future<AlipayPaymentRequest> initiateAlipay(PaymentOrder order) {
    return _repository.initiateAlipay(order);
  }

  Future<PaymentStatus> queryPaymentStatus(String paymentId) {
    return _repository.queryPaymentStatus(paymentId);
  }

  Future<PaymentOrder> simulatePaymentSuccess(PaymentOrder order) async {
    await Future.delayed(const Duration(seconds: 2));
    return order.copyWith(
      status: PaymentStatus.confirmed,
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      paidAt: DateTime.now(),
    );
  }

  Future<OrderPaymentStatusResult?> submitOrderPayment({
    required String orderId,
    required PaymentMethod method,
  }) {
    return _repository.submitOrderPayment(orderId: orderId, method: method);
  }

  Future<OrderPaymentStatusResult?> queryOrderPaymentStatus(String orderId) {
    return _repository.queryOrderPaymentStatus(orderId);
  }

  Future<bool> cancelPayment(String paymentId) {
    return _repository.cancelPayment(paymentId);
  }

  Future<RefundRequestResult> requestRefund({
    required String orderId,
    required String paymentId,
    required double amount,
    String? reason,
  }) {
    return _repository.requestRefund(
      orderId: orderId,
      paymentId: paymentId,
      amount: amount,
      reason: reason,
    );
  }

  Future<RefundStatusResult> queryRefundStatus(String refundId) {
    return _repository.queryRefundStatus(refundId);
  }

  static String getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wechat:
        return '💚';
      case PaymentMethod.alipay:
        return '💙';
      case PaymentMethod.unionpay:
        return '❤️';
      case PaymentMethod.balance:
        return '💰';
    }
  }

  static String formatAmount(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }
}

typedef PaymentCallback = void Function(bool success, String? message);
